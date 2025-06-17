const functions = require("firebase-functions")
const admin = require("firebase-admin")
const nodemailer = require("nodemailer")

admin.initializeApp()

// Send appointment reminder notifications
exports.sendAppointmentReminders = functions.pubsub.schedule("every 1 hours").onRun(async (context) => {
  const now = admin.firestore.Timestamp.now()
  const oneHourLater = new Date(now.toMillis() + 60 * 60 * 1000)
  const twoHoursLater = new Date(now.toMillis() + 2 * 60 * 60 * 1000)

  // Get appointments in the next 1-2 hours
  const snapshot = await admin
    .firestore()
    .collection("appointments")
    .where("date", ">=", admin.firestore.Timestamp.fromDate(oneHourLater))
    .where("date", "<", admin.firestore.Timestamp.fromDate(twoHoursLater))
    .where("status", "==", "scheduled")
    .get()

  const promises = []

  snapshot.forEach((doc) => {
    const appointment = doc.data()

    // Get user's FCM token
    const userPromise = admin
      .firestore()
      .collection("users")
      .doc(appointment.userId)
      .get()
      .then((userDoc) => {
        const userData = userDoc.data()
        const fcmToken = userData.fcmToken

        if (fcmToken) {
          // Send notification
          return admin.messaging().send({
            token: fcmToken,
            notification: {
              title: "Upcoming Appointment",
              body: `You have an appointment with ${appointment.clientName} in about an hour.`,
            },
            data: {
              appointmentId: doc.id,
              type: "reminder",
            },
          })
        }

        return null
      })

    promises.push(userPromise)
  })

  await Promise.all(promises)

  return null
})

// Send monthly reports
exports.sendMonthlyReports = functions.pubsub.schedule("0 0 1 * *").onRun(async (context) => {
  // Get all users
  const usersSnapshot = await admin.firestore().collection("users").get()

  const now = new Date()
  const firstDayLastMonth = new Date(now.getFullYear(), now.getMonth() - 1, 1)
  const lastDayLastMonth = new Date(now.getFullYear(), now.getMonth(), 0)

  const promises = []

  // Configure email transporter
  const transporter = nodemailer.createTransport({
    service: "gmail",
    auth: {
      user: functions.config().email.user,
      pass: functions.config().email.password,
    },
  })

  usersSnapshot.forEach((userDoc) => {
    const user = userDoc.data()

    if (!user.email) return

    // Get appointments for last month
    const appointmentsPromise = admin
      .firestore()
      .collection("appointments")
      .where("userId", "==", userDoc.id)
      .where("date", ">=", admin.firestore.Timestamp.fromDate(firstDayLastMonth))
      .where("date", "<", admin.firestore.Timestamp.fromDate(lastDayLastMonth))
      .get()
      .then(async (appointmentsSnapshot) => {
        const appointments = []
        let totalAppointments = 0

        appointmentsSnapshot.forEach((doc) => {
          appointments.push(doc.data())
          totalAppointments++
        })

        // Get billing for last month
        const billingSnapshot = await admin
          .firestore()
          .collection("documents")
          .where("userId", "==", userDoc.id)
          .where("createdAt", ">=", admin.firestore.Timestamp.fromDate(firstDayLastMonth))
          .where("createdAt", "<", admin.firestore.Timestamp.fromDate(lastDayLastMonth))
          .get()

        let totalBilling = 0
        let totalDocuments = 0

        billingSnapshot.forEach((doc) => {
          const document = doc.data()
          totalBilling += document.amount || 0
          totalDocuments++
        })

        // Format month name
        const monthName = firstDayLastMonth.toLocaleString("default", { month: "long" })

        // Send email report
        return transporter.sendMail({
          from: '"PlanAndBill" <noreply@planandbill.com>',
          to: user.email,
          subject: `Your Monthly Report - ${monthName} ${firstDayLastMonth.getFullYear()}`,
          html: `
            <h1>Monthly Activity Report</h1>
            <p>Hello ${user.displayName || "Therapist"},</p>
            <p>Here's your activity summary for ${monthName} ${firstDayLastMonth.getFullYear()}:</p>
            
            <h2>Appointments</h2>
            <p>Total appointments: <strong>${totalAppointments}</strong></p>
            
            <h2>Billing</h2>
            <p>Total documents generated: <strong>${totalDocuments}</strong></p>
            <p>Total amount billed: <strong>€${totalBilling.toFixed(2)}</strong></p>
            
            <p>Thank you for using PlanAndBill!</p>
          `,
        })
      })

    promises.push(appointmentsPromise)
  })

  await Promise.all(promises)

  return null
})

// Create document when appointment is completed
exports.createBillOnAppointmentComplete = functions.firestore
  .document("appointments/{appointmentId}")
  .onUpdate(async (change, context) => {
    const before = change.before.data()
    const after = change.after.data()

    // Check if status changed to completed
    if (before.status !== "completed" && after.status === "completed") {
      // Get user's billing settings
      const userDoc = await admin.firestore().collection("users").doc(after.userId).get()

      const userData = userDoc.data()

      // Check if auto-billing is enabled
      if (userData.autoBilling) {
        // Create bill document
        await admin
          .firestore()
          .collection("documents")
          .add({
            userId: after.userId,
            type: "bill",
            title: `Session with ${after.clientName}`,
            clientName: after.clientName,
            description: `Therapy session on ${after.date.toDate().toLocaleDateString()}`,
            amount: userData.defaultRate || 0,
            issueDate: admin.firestore.FieldValue.serverTimestamp(),
            dueDate: admin.firestore.Timestamp.fromDate(new Date(Date.now() + 30 * 24 * 60 * 60 * 1000)),
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            appointmentId: context.params.appointmentId,
          })
      }
    }

    return null
  })
