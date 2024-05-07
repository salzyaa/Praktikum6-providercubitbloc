import 'package:flutter/material.dart'; 
import 'package:http/http.dart' as http; // Mengimpor package http.dart dari package http dengan alias http.
import 'dart:convert'; 
import 'package:flutter_bloc/flutter_bloc.dart'; // Mengimpor package flutter_bloc.dart untuk implementasi Flutter Bloc.

class UniversityCubit extends Cubit<List<University>> { // Membuat class UniversityCubit yang merupakan Cubit.
  UniversityCubit() : super([]); // Constructor UniversityCubit yang menginisialisasi state dengan list kosong.

  Map<String, List<University>> cache = {}; // Penyimpanan cache untuk data universitas

  Future<void> fetchUniversities(String country) async {
    if (cache.containsKey(country)) { // Memeriksa apakah data sudah ada di cache.
      emit(cache[country]!); // Mengeluarkan data dari cache jika tersedia.
    } else {
      String url = "http://universities.hipolabs.com/search?country=$country"; // URL API untuk mendapatkan universitas berdasarkan negara.
      final response = await http.get(Uri.parse(url)); // Mengirimkan permintaan HTTP GET ke URL.
      if (response.statusCode == 200) { // Jika permintaan berhasil.
        List<dynamic> data = jsonDecode(response.body); // Mendapatkan data JSON dari respons.
        List<University> universities = data
            .map((e) => University(name: e["name"], website: e["web_pages"][0]))
            .toList(); // Mengonversi data JSON menjadi list objek University.
        cache[country] = universities; // Menyimpan data universitas ke dalam cache.
        emit(universities); // Memperbarui state dengan data universitas yang diperoleh.
      } else {
        throw Exception('Failed to load universities'); // Melemparkan pengecualian jika gagal memuat universitas.
      }
    }
  }
}

class University { // Membuat class University untuk merepresentasikan objek universitas.
  String name; // Properti untuk menyimpan nama universitas.
  String website; // Properti untuk menyimpan website universitas.

  University({required this.name, required this.website}); // Constructor dengan parameter wajib.
}

final List<String> countries = [ // List negara-negara ASEAN.
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

void main() {
  runApp(MyApp()); // Memulai aplikasi Flutter.
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Universitas di ASEAN',
      home: MultiBlocProvider(
        providers: [
          BlocProvider(create: (context) => UniversityCubit()), // Memberikan UniversityCubit sebagai provider Bloc.
        ],
        child: UniversityApp(), // Memulai aplikasi dengan widget UniversityApp.
      ),
    );
  }
}

class UniversityApp extends StatefulWidget { // Widget utama aplikasi.
  @override
  _UniversityAppState createState() => _UniversityAppState(); // Membuat state dari widget UniversityApp.
}

class _UniversityAppState extends State<UniversityApp> {
  late UniversityCubit universityCubit; // Cubit untuk mengakses state dan method.

  String selectedCountry = ''; // Inisialisasi dengan string kosong
  bool isLoading = false; // Variabel untuk menunjukkan status pemrosesan data.

  @override
  void initState() {
    super.initState();
    universityCubit = context.read<UniversityCubit>(); // Menggunakan context.read untuk mendapatkan instance dari UniversityCubit.
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Universitas di ASEAN'),
      ),
      body: Center(
        child: SingleChildScrollView( // Tambahkan SingleChildScrollView untuk memungkinkan scrolling.
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Center(
                child: DropdownButton<String>(
                  value: selectedCountry.isNotEmpty ? selectedCountry : null, // Gunakan null untuk tampilan default kosong
                  hint: Text('Pilih Negara'), // Hint untuk dropdown
                  items: countries.map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        selectedCountry = newValue; // Perbarui nilai selectedCountry saat negara dipilih.
                        isLoading = true; // Set isLoading true saat memuat data baru.
                      });
                      universityCubit.fetchUniversities(newValue).then((_) {
                        setState(() {
                          isLoading = false; // Set isLoading false saat selesai memuat data.
                        });
                      }).catchError((error) {
                        setState(() {
                          isLoading = false; // Set isLoading false jika terjadi error.
                        });
                        // Handle error here
                      });
                    }
                  },
                ),
              ),
              if (isLoading)
                CircularProgressIndicator() // Tampilkan CircularProgressIndicator saat memuat data.
              else
                BlocBuilder<UniversityCubit, List<University>>( // Widget BlocBuilder untuk mendengarkan perubahan state dari UniversityCubit.
                  builder: (context, universities) {
                    return ListView.separated( // Tampilkan daftar universitas dengan ListView.
                      shrinkWrap: true,
                      itemCount: universities.length,
                      separatorBuilder: (context, index) => Divider(
                        color: Colors.grey,
                        thickness: 1,
                      ),
                      itemBuilder: (context, index) {
                        return ListTile(
                          title: Text(universities[index].name),
                          subtitle: Text(universities[index].website),
                        );
                      },
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}
