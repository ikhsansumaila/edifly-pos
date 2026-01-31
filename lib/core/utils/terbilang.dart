String pembilang(double nilai) {
  List<String> huruf = [
    "",
    "Satu",
    "Dua",
    "Tiga",
    "Empat",
    "Lima",
    "Enam",
    "Tujuh",
    "Delapan",
    "Sembilan",
    "Sepuluh",
    "Sebelas",
  ];
  String temp = "";

  if (nilai < 12) {
    temp = " ${huruf[nilai.toInt()]}";
  } else if (nilai < 20) {
    temp = "${pembilang(nilai - 10)} Belas";
  } else if (nilai < 100) {
    temp = "${pembilang(nilai / 10)} Puluh${pembilang(nilai % 10)}";
  } else if (nilai < 200) {
    temp = " Seratus${pembilang(nilai - 100)}";
  } else if (nilai < 1000) {
    temp = "${pembilang(nilai / 100)} Ratus${pembilang(nilai % 100)}";
  } else if (nilai < 2000) {
    temp = " Seribu${pembilang(nilai - 1000)}";
  } else if (nilai < 1000000) {
    temp = "${pembilang(nilai / 1000)} Ribu${pembilang(nilai % 1000)}";
  } else if (nilai < 1000000000) {
    temp = "${pembilang(nilai / 1000000)} Juta${pembilang(nilai % 1000000)}";
  } else if (nilai < 1000000000000) {
    temp = "${pembilang(nilai / 1000000000)} Milyar${pembilang(nilai % 1000000000)}";
  } else if (nilai < 1000000000000000) {
    temp = "${pembilang(nilai / 1000000000000)} Trilyun${pembilang(nilai % 1000000000000)}";
  }

  return temp;
}

String terbilang(dynamic value) {
  if (value == null) return "";
  double n = 0;
  if (value is int) {
    n = value.toDouble();
  } else if (value is double) {
    n = value;
  } else if (value is String) {
    n = double.tryParse(value) ?? 0;
  }

  if (n < 0) {
    return "Minus ${pembilang(n.abs()).trim()}";
  } else if (n == 0) {
    return "Nol Rupiah";
  }

  return ("${pembilang(n)} Rupiah").trim();
}
