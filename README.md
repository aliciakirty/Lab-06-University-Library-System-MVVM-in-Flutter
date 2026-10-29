# Lab 06 — University Library System: MVVM in Flutter

### What is the difference between the Model, View, and ViewModel in this application?
Model digunakan untuk menyimpan data mengenai Book dan Loan, View menampilkan tampilan kepada pengguna, ViewModel untuk menjalankan logikanya / cara kerjanya serta menjadi penghubung antara Model dan juga View.

### What should happen if a student attempts to borrow a book that already has an active loan?
Jika quantity buku masih tersedia, buku tetap dapat dipinjam. Peminjaman ditolak jika seluruh quantity buku sudah habis dipinjam.

### Why is it better to calculate the fine in one place rather than repeating the formula in multiple widgets?
Agar aturan denda tetap konsisten dan mencegah perbedaan hasil perhitungan pada widget yang berbeda.

### What is the difference between a book being Overdue and being Missing?
Overdue artinya buku sudah melewati tanggal jatuh tempo tetapi belum mencapai batas enam bulan. Missing berarti buku sudah terlambat selama enam bulan atau lebih.

### If the university changes its weekly fine from Rp5,000 to Rp7,000, how should the app be updated?
Perubahan cukup dilakukan pada fungsi 'calculateFine()' dari Rp5.000 menjadi Rp7.000, sehingga seluruh bagian aplikasi otomatis menggunakan aturan denda yang baru.