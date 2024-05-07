import 'package:flutter/material.dart'; // Import package Flutter Material untuk membangun UI
import 'package:http/http.dart' as http; // Import package http untuk melakukan HTTP request
import 'dart:convert'; // Import package untuk mengonversi data
import 'package:flutter_bloc/flutter_bloc.dart'; // Import package Flutter Bloc untuk manajemen state

// Model untuk menyimpan data universitas
class Situs {
  List<University> universities = []; // List untuk menyimpan data universitas

  // Konstruktor untuk membuat objek Situs dari data JSON
  Situs.fromJson(List<dynamic> json) {
    // Iterasi melalui setiap data JSON dan menambahkannya ke dalam list universities
    for (var val in json) {
      var name = val["name"]; // Ambil nama universitas
      var website = val["web_pages"][0]; // Ambil website universitas
      universities.add(University(name: name, website: website)); // Tambahkan universitas ke dalam list
    }
  }
}

// Event untuk melakukan fetching data
abstract class SitusEvent {}

// Event untuk melakukan fetching data berdasarkan negara tertentu
class FetchData extends SitusEvent {
  final String country; // Nama negara

  FetchData(this.country); // Konstruktor untuk inisialisasi event
}

// State untuk manajemen state aplikasi
abstract class SitusState {}

// State awal saat aplikasi dijalankan
class SitusInitial extends SitusState {}

// State saat aplikasi sedang melakukan proses fetching data
class SitusLoading extends SitusState {}

// State saat data berhasil di-load
class SitusLoaded extends SitusState {
  final Situs situs; // Objek Situs yang berisi data universitas

  SitusLoaded(this.situs); // Konstruktor untuk inisialisasi state
}

// State saat terjadi error saat fetching data
class SitusError extends SitusState {
  final String error; // Pesan error

  SitusError(this.error); // Konstruktor untuk inisialisasi error state
}

// Bloc untuk manajemen state aplikasi
class SitusBloc extends Bloc<SitusEvent, SitusState> {
  SitusBloc() : super(SitusInitial()) { // Konstruktor untuk inisialisasi state awal
    // Handler untuk event FetchData
    on<FetchData>((event, emit) async {
      await _handleFetchData(event, emit); // Panggil method untuk melakukan fetching data
    });
  }

  // Method untuk melakukan fetching data
  Future<void> _handleFetchData(
      FetchData event, Emitter<SitusState> emit) async {
    try {
      emit(SitusLoading()); // Emit SitusLoading state saat fetching data dimulai
      final Situs situs = await fetchData(event.country); // Panggil method fetchData untuk mengambil data
      emit(SitusLoaded(situs)); // Emit SitusLoaded state dengan data yang berhasil di-load
    } catch (e) {
      emit(SitusError('Gagal load')); // Jika terjadi error, emit SitusError state
    }
  }

  // Method untuk melakukan fetching data dari API
  Future<Situs> fetchData(String country) async {
    String url = "http://universities.hipolabs.com/search?country=$country"; // URL API untuk mengambil data universitas berdasarkan negara
    final response = await http.get(Uri.parse(url)); // Lakukan HTTP GET request
    if (response.statusCode == 200) {
      return Situs.fromJson(jsonDecode(response.body)); // Jika respons berhasil, kembalikan data Situs dari JSON
    } else {
      throw Exception('Gagal load'); // Jika terjadi error, lempar exception
    }
  }
}

// Model untuk menyimpan data universitas
class University {
  String name; // Nama universitas
  String website; // Website universitas

  University({required this.name, required this.website}); // Konstruktor untuk inisialisasi objek University

  // Factory method untuk membuat objek University dari JSON
  factory University.fromJson(Map<String, dynamic> json) {
    return University(
      name: json['name'],
      website: json['website'],
    );
  }
}

// Widget dropdown untuk memilih negara
class CountryDropdown extends StatelessWidget {
  final List<String> countries = [ // List negara-negara ASEAN
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
  Widget build(BuildContext context) {
    return DropdownButton<String>(
      value: null, // Nilai default dropdown
      hint: Text('Pilih Negara'), // Hint untuk dropdown
      items: countries.map<DropdownMenuItem<String>>((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value),
        );
      }).toList(),
      onChanged: (String? newValue) { // Callback saat nilai dropdown berubah
        if (newValue != null) {
          BlocProvider.of<SitusBloc>(context).add(FetchData(newValue)); // Panggil event FetchData saat nilai dropdown berubah
        }
      },
    );
  }
}

// Main method untuk menjalankan aplikasi Flutter
void main() {
  runApp(
    BlocProvider( // Provider untuk Bloc SitusBloc
      create: (context) => SitusBloc(), // Buat instance SitusBloc
      child: MyApp(), // Widget utama aplikasi
    ),
  );
}

// Widget utama aplikasi
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Universitas di ASEAN', // Judul aplikasi
      home: UniversityApp(), // Widget home adalah UniversityApp
    );
  }
}

// Widget untuk menampilkan daftar universitas
class UniversityApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Universities in ASEAN'), // Judul AppBar
      ),
      body: Column( // Widget body berupa Column
        children: [
          CountryDropdown(), // Widget dropdown untuk memilih negara
          Expanded( // Widget Expanded agar ListView bisa menyesuaikan ukuran
            child: BlocBuilder<SitusBloc, SitusState>( // BlocBuilder untuk membangun UI berdasarkan state
              builder: (context, state) { // Builder untuk membangun UI berdasarkan state
                if (state is SitusLoading) { // Jika state adalah SitusLoading
                  return Center(child: CircularProgressIndicator()); // Tampilkan CircularProgressIndicator
                } else if (state is SitusError) { // Jika state adalah SitusError
                  return Center(child: Text(state.error)); // Tampilkan pesan error
                } else if (state is SitusLoaded) { // Jika state adalah SitusLoaded
                  return ListView.builder( // Tampilkan ListView untuk menampilkan daftar universitas
                    itemCount: state.situs.universities.length, // Jumlah item ListView sesuai dengan jumlah universitas
                    itemBuilder: (context, index) { // ItemBuilder untuk membangun setiap item ListView
                      return ListTile( // Widget ListTile untuk menampilkan informasi universitas
                        title: Text(state.situs.universities[index].name), // Nama universitas
                        subtitle: Text(state.situs.universities[index].website), // Website universitas
                      );
                    },
                  );
                }
                return Container(); // Kembalikan Container kosong jika state tidak sesuai
              },
            ),
          ),
        ],
      ),
    );
  }
}
