# Crear cuenta principal
account = Account.create!(
  name: 'Mi Empresa',
  status: 'active'
)
puts "✅ Cuenta creada: #{account.name}"

# Crear usuario administrador
user = User.create!(
  email: 'gandresalcedo09@gmail.com',
  password: 'AmomuchoaEdtools_2025',
  password_confirmation: 'AmomuchoaEdtools_2025',
  name: 'Administrador',
  confirmed_at: Time.current
)
puts "✅ Usuario creado: #{user.email}"

# Asociar usuario con la cuenta como administrador
AccountUser.create!(
  account: account,
  user: user,
  role: 'administrator'
)
puts '✅ Permisos de administrador asignados'
puts ''
puts '🎉 ¡Listo! Credenciales de acceso:'
puts '📧 Email: gandresalcedo09@gmail.com'
puts '🔑 Password: AmomuchoaEdtools_2025'