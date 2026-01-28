const bcrypt = require('bcryptjs');

async function generate() {
  const adminHash = await bcrypt.hash('admin123', 10);
  const securityHash = await bcrypt.hash('security123', 10);

  console.log('Admin hash:', adminHash);
  console.log('Security hash:', securityHash);
}

generate();
