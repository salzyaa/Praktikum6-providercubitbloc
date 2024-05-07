import 'package:flutter/material.dart'; 
import 'package:http/http.dart' as http; // Mengimpor package http.dart dari package http 
import 'dart:convert'; 
import 'package:provider/provider.dart'; // Mengimpor package provider.dart untuk state management.

// Mendefinisikan kelas University dengan dua properti: name dan website
class University {
  String name; // Menyimpan nama universitas
  String website; // Menyimpan website universitas

  University({required this.name, required this.website}); // Konstruktor dengan parameter wajib.
}

// Mendefinisikan kelas UniversityList untuk mengelola daftar universitas
class UniversityList {
  late List<University> universities; // Daftar objek University
  UniversityList(List<dynamic> json) {
    universities = json.map((data) {
      return University(
        name: data["name"],
        website: data["web_pages"][0],
      );
    }).toList(); // Menginisialisasi daftar universitas berdasarkan data JSON yang diterima.
  }
}

void main() {
  runApp(
    ChangeNotifierProvider( // Memanfaatkan ChangeNotifierProvider untuk state management.
      create: (context) => UniversityProvider(), // Membuat instance dari UniversityProvider.
      child: MyApp(), // Memulai aplikasi dengan widget MyApp.
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Universitas di ASEAN', // Judul aplikasi
      home: UniversityApp(), // Memulai aplikasi dengan widget UniversityApp.
    );
  }
}

class UniversityApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Universitas di ASEAN'), // Judul AppBar.
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CountryDropdown(), // Menampilkan combobox untuk memilih negara.
            UniversityListWidget(), // Menampilkan daftar universitas.
          ],
        ),
      ),
    );
  }
}

class CountryDropdown extends StatefulWidget {
  @override
  _CountryDropdownState createState() => _CountryDropdownState();
}

class _CountryDropdownState extends State<CountryDropdown> {
  late String selectedCountry; // Menyimpan negara yang dipilih.
  final List<String> countries = [
    'Pilih Negara', // Opsi kosong pertama dalam combobox.
    'Brunei Darussalam',
    'Cambodia',
    'Indonesia',
    'Lao People\'s Democratic Republic',
    'Malaysia',
    'Myanmar',
    'Philippines',
    'Singapore',
    'Thailand',
    'Vietnam'
  ];

  @override
  void initState() {
    super.initState();
    selectedCountry = 'Pilih Negara'; // Menginisialisasi negara yang dipilih.
  }

  @override
  Widget build(BuildContext context) {
    final universityProvider = Provider.of<UniversityProvider>(context); // Mendapatkan instance dari UniversityProvider.

    return DropdownButton<String>(
      value: selectedCountry,
      onChanged: (String? newValue) {
        if (newValue != null) {
          setState(() {
            selectedCountry = newValue;
          });
          if (newValue.isNotEmpty) { // Memanggil fetchUniversities jika negara dipilih.
            universityProvider.fetchUniversities(newValue);
          }
        }
      },
      items: countries.map<DropdownMenuItem<String>>((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: value.isNotEmpty ? Text(value) : SizedBox.shrink(), // Tampilkan teks untuk nilai yang tidak kosong.
        );
      }).toList(),
    );
  }
}

class UniversityListWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final universityProvider = Provider.of<UniversityProvider>(context); // Mendapatkan instance dari UniversityProvider.
    final universities = universityProvider.universities; // Mendapatkan daftar universitas dari UniversityProvider.

    return universities.isEmpty
        ? CircularProgressIndicator() // Menampilkan CircularProgressIndicator saat memuat data.
        : Expanded(
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: universities.length,
              separatorBuilder: (context, index) => Divider(
                color: Colors.grey,
                thickness: 1,
              ),
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(universities[index].name), // Menampilkan nama universitas.
                  subtitle: Text(universities[index].website), // Menampilkan website universitas.
                );
              },
            ),
          );
  }
}

class UniversityProvider extends ChangeNotifier {
  late List<University> _universities = []; // Daftar universitas yang akan dimuat.

  List<University> get universities => _universities; // Getter untuk daftar universitas.

  Future<void> fetchUniversities(String country) async {
    final String url = "http://universities.hipolabs.com/search?country=$country"; // URL API untuk mendapatkan universitas berdasarkan negara.
    final response = await http.get(Uri.parse(url)); // Mengirimkan permintaan HTTP GET ke URL.
    if (response.statusCode == 200) { // Jika permintaan berhasil.
      List<dynamic> data = jsonDecode(response.body); // Mendapatkan data JSON dari respons.
      _universities = UniversityList(data).universities; // Menginisialisasi daftar universitas dari data JSON.
      notifyListeners(); // Memberitahu listener bahwa daftar universitas telah diperbarui.
    } else {
      throw Exception('Failed to load universities'); // Melemparkan pengecualian jika gagal memuat universitas.
    }
  }
}
