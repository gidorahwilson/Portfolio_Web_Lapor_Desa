require 'sinatra'
require 'mysql2'
require 'base64'
require 'dotenv/load'

def db
  @db ||= Mysql2::Client.new(
    host: ENV['DB_HOST'],
    username: ENV['DB_USER'],
    password: ENV['DB_PASS'],
    database: ENV['DB_NAME'],
    reconnect: true
  )
end



#Routing
enable :sessions

get '/' do
  erb:index
end
get '/gagal_daftar' do
  erb:gagal_daftar
end
get '/gagal_login' do
  erb:gagal_login
end
get '/gagal_login2' do
  erb:gagal_login2
end
get '/dashboard' do
  erb:dashboardadmin
end
get '/login_admin' do
  erb:AdminPengelola
end
get '/akses_ditolak' do
  erb:akses_ditolak
end
before '/dashboardadmin*' do
  unless session[:dashboardadmin]
    redirect '/akses_ditolak'
  end
end
get '/logout' do
  session.clear
  redirect '/login_admin'
end

#Daftar
post '/register' do
  nama  = params['nama_lengkap'].to_s.strip
  email = params['email'].to_s.strip
  hp    = params['hp'].to_s.strip
  pass  = params['password'].to_s.strip

  if nama.empty? || email.empty? || hp.empty? || pass.empty?
    redirect '/gagal_daftar'
  end

  sql = db.prepare("INSERT INTO daftar(nama_lengkap, email, hp, password) VALUES(?, ?, ?, ?)")
  sql.execute(nama, email, hp, pass)

  erb:berhasil_login
end

#Login
post '/login' do
  email = params['email']
  pass  = params['password']

  if email.empty? || pass.empty?
    redirect '/gagal_login'
  end

  sql2 = db.prepare("SELECT * FROM daftar WHERE email=? AND password=?")
  result = sql2.execute(email, pass)

  if result.count > 0
    erb:pengaduan
  else
    erb:gagal_login
  end
end

#Pengaduan
post '/kirim_pengaduan' do
  nama      = params['nama']
  hp        = params['hp']
  kategori  = params['kategori']
  lokasi    = params['lokasi']
  pengaduan = params['pengaduan']
  foto1     = params[:foto][:tempfile]
  foto2     = params[:foto][:filename]
  data      = foto1.read

  if nama.empty? || hp.empty? || kategori.empty? || lokasi.empty? || pengaduan.empty?
    redirect '/gagal_daftar'
  end

  sql3 = db.prepare("INSERT INTO lapor(nama, hp, kategori, lokasi, pengaduan, foto) VALUES(?, ?, ?, ?, ?, ?)")
  sql3.execute(nama, hp, kategori, lokasi, pengaduan, data)

  erb:pengaduan
end

#Pengaduan-Route foto
get '/foto/:nama' do
  nama = params[:nama]

  row = db.prepare("SELECT foto FROM lapor WHERE nama=?")
          .execute(nama)
          .first

  bytes = row['foto']

  if bytes.start_with?("\xFF\xD8".b)
    content_type 'image/jpeg'
  elsif bytes.start_with?("\x89PNG".b)
    content_type 'image/png'
  end

  bytes
end

#Login-ADMIN
post '/admin/login' do
  username = params['username']
  password = params['password']

  sql4  = db.prepare("SELECT * FROM admin WHERE username=? AND password=?")
  query = sql4.execute(username, password).first

  if query
    session[:dashboardadmin] = query['username']
    redirect '/dashboardadmin'
  else
    erb:gagal_login2
  end
end

get '/dashboardadmin' do
  sql5   = "SELECT * FROM lapor"
  @hasil = db.query(sql5)
  erb:dashboardadmin
end

get '/hapus_lapor/:nama' do
  nama = params['nama']

  sql7 = db.prepare("DELETE FROM lapor WHERE nama=?")
  sql7.execute(nama)
  redirect '/dashboardadmin'
end

#Register-ADMIN
get '/regis-%7C-admin' do
  erb:tryregist_admin
end
post '/regis-%7C-admin' do
  username = params['username']
  password = params['password']

  if username.empty? || password.empty?
    redirect '/gagal_daftar'
  end

  sql6 = db.prepare("INSERT INTO admin(username, password) VALUES(?, ?)")
  sql6.execute(username, password)

  erb:berhasil_login_admin
end
