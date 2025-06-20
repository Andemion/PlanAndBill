import 'dart:typed_data';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:planandbill/models/invoice.dart';


class EmailService {

  Future<void> shareInvoicePdf(Uint8List pdfData,
      Invoice invoice,) async {
    final tempDir = await getTemporaryDirectory();
    final filePath = '${tempDir.path}/${invoice.number}.pdf';
    final file = File(filePath);
    await file.writeAsBytes(pdfData);

    // Détermine le type de document
    final isInvoice = invoice.number.toLowerCase().contains('facture');
    final docType = isInvoice ? 'facture' : 'devis';

    // Vas chercher email du clients en base
    final clientSnapshot = await FirebaseFirestore.instance
        .collection('clients')
        .doc(invoice.clientId)
        .get();

    final clientData = clientSnapshot.data();
    final clientEmail = clientData?['email'] ?? 'email non renseigné';

    // Prépare le message
    final subject = 'Votre $docType ${invoice.number}';
    final message = '''
      ${clientEmail}
      Bonjour ${invoice.clientName},
      
      Veuillez trouver ci-joint votre $docType concernant notre rendez-vous du ${DateFormat(
          'dd/MM/yyyy').format(invoice.date)}.
      
      N'hésitez pas à me contacter si vous avez des questions.
      
      Bien cordialement,
      
      Caroline Clerc
    ''';

    // Ouvre le client mail avec pièce jointe et contenu en français
    await Share.shareXFiles(
      [XFile(file.path)],
      subject: subject,
      text: message,
    );
  }
}