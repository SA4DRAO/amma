import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class CreditsScreen extends StatelessWidget {
  const CreditsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Credits'),
      ),
      body: ListView(
        children: [
          _buildCreditTile(
            name: 'Dr. Kadambari K V',
            image: 'assets/kadambari_kv.jpg', // Replace with actual image path
            linkedInUrl: 'https://www.linkedin.com/in/kadambari-k-v-50a05865/',
            githubUrl: '', // Add GitHub URL if available
          ),
          _buildCreditTile(
            name: 'Adarsh Rao',
            image: 'assets/adarsh_rao.jpeg', // Replace with actual image path
            linkedInUrl: 'https://www.linkedin.com/in/sa4drao/',
            githubUrl: 'https://github.com/SA4DRAO',
          ),
          _buildCreditTile(
            name: 'Farzan Nizam',
            image: 'assets/farzan_nizam.jpeg', // Replace with actual image path
            linkedInUrl: 'https://www.linkedin.com/in/farzan-nizam/',
            githubUrl: 'https://github.com/farzannizam',
          ),
        ],
      ),
    );
  }

  Widget _buildCreditTile({
    required String name,
    required String image,
    required String linkedInUrl,
    required String githubUrl,
  }) {
    return ListTile(
      title: Text(name),
      leading: CircleAvatar(
        backgroundImage: AssetImage(image),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (linkedInUrl.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.link),
              onPressed: () {
                _launchURL(linkedInUrl);
              },
            ),
          if (githubUrl.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.code),
              onPressed: () {
                _launchURL(githubUrl);
              },
            ),
          // Add more buttons for other platforms if needed
        ],
      ),
    );
  }

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      throw 'Could not launch $url';
    }
  }
}
