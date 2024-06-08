import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart'; // Add this line

class CreditsScreen extends StatelessWidget {
  const CreditsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Credits'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildCreditCard(
            name: 'Dr. Kadambari K V',
            image: 'assets/kadambari_kv.jpg', // Replace with actual image path
            linkedInUrl:
                'https://wsdc.nitw.ac.in/facultynew/facultyprofile/id/16335',
            githubUrl: '', // Add GitHub URL if available
          ),
          _buildCreditCard(
            name: 'Adarsh Rao',
            image: 'assets/adarsh_rao.jpeg', // Replace with actual image path
            linkedInUrl: 'https://www.linkedin.com/in/sa4drao/',
            githubUrl: 'https://github.com/SA4DRAO',
          ),
          _buildCreditCard(
            name: 'Farzan Nizam',
            image: 'assets/farzan_nizam.jpeg', // Replace with actual image path
            linkedInUrl: 'https://www.linkedin.com/in/farzan-nizam1393/',
            githubUrl: 'https://github.com/fuNse',
          ),
        ],
      ),
    );
  }

  Widget _buildCreditCard({
    required String name,
    required String image,
    required String linkedInUrl,
    required String githubUrl,
  }) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16.0),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16.0),
        title: Text(
          name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: CircleAvatar(
          radius: 30,
          backgroundImage: AssetImage(image),
        ),
        trailing: Wrap(
          spacing: 8.0,
          children: [
            if (linkedInUrl.isNotEmpty)
              IconButton(
                icon: githubUrl.isEmpty
                    ? Image.asset(
                        'assets/nitw_logo.png', // Provide the NIT Warangal logo asset
                        width: 24,
                        height: 24,
                      )
                    : Image.asset(
                        'assets/linkedin_logo.png', // Provide the LinkedIn logo asset
                        width: 24,
                        height: 24,
                      ),
                onPressed: () {
                  _launchURL(linkedInUrl);
                },
              ),
            if (githubUrl.isNotEmpty)
              IconButton(
                icon: Image.asset(
                  'assets/github_logo.png', // Provide the GitHub logo asset
                  width: 24,
                  height: 24,
                ),
                onPressed: () {
                  _launchURL(githubUrl);
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      try {
        await launchUrl(uri);
      } catch (e) {
        // Handle the exception here, e.g., show an error message
        print('Error launching URL: $e');
      }
    } else {
      // Handle the case where the URL cannot be launched
      print('Could not launch $url');
    }
  }
}
