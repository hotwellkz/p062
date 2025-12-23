# 🔧 СРОЧНО: Исправление SSH-ключа на Synology

## ⚠️ Проблема

Вы добавили **пароль** (`6999LqJiQguX`) в `~/.ssh/authorized_keys` вместо **публичного ключа**!

Это нужно исправить.

## ✅ Быстрое исправление

### Шаг 1: Получите публичный ключ

Ваш публичный ключ:
```
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEaCnkuoQkYJ4csaIuP3M6HPziDk0x0flrBzx2nyXjl6 synology-access
```

### Шаг 2: Подключитесь к Synology

Вы уже подключены к Synology через VPS. Если нет:

```powershell
ssh root@159.255.37.158
ssh admin@10.8.0.2
```

### Шаг 3: Исправьте authorized_keys

На Synology выполните:

```bash
# Удалите неправильную запись с паролем
cat ~/.ssh/authorized_keys
# Вы увидите строку с "6999LqJiQguX" - её нужно удалить

# Удалите файл и создайте заново (проще всего)
rm ~/.ssh/authorized_keys

# Создайте файл заново с правильным ключом
mkdir -p ~/.ssh
chmod 700 ~/.ssh
echo "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEaCnkuoQkYJ4csaIuP3M6HPziDk0x0flrBzx2nyXjl6 synology-access" > ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys

# Проверьте содержимое
cat ~/.ssh/authorized_keys
```

**Должна быть только одна строка, начинающаяся с `ssh-ed25519`!**

### Шаг 4: Проверьте подключение

Выйдите из Synology и VPS, затем на вашем компьютере:

```powershell
# Прямое подключение
ssh -i C:\Users\studo\.ssh\shortsai_synology admin@192.168.100.222 'echo "SSH key works!"'
```

Если подключение работает **без пароля** — готово! ✅

## Альтернатива: одной командой

Если вы всё ещё подключены к Synology, выполните:

```bash
# На Synology
cat > ~/.ssh/authorized_keys << 'EOF'
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEaCnkuoQkYJ4csaIuP3M6HPziDk0x0flrBzx2nyXjl6 synology-access
EOF
chmod 600 ~/.ssh/authorized_keys
```

## Проверка

После исправления проверьте:

```bash
# На Synology
cat ~/.ssh/authorized_keys
ls -la ~/.ssh/
```

Должно быть:
- `authorized_keys` содержит только строку с `ssh-ed25519`
- Права: `-rw-------` (600)
- Директория `.ssh`: `drwx------` (700)

## После исправления

Обновите SSH config на вашем компьютере:

```powershell
# Добавьте в C:\Users\studo\.ssh\config:

Host synology-shortsai
    HostName 10.8.0.2
    User admin
    IdentityFile ~/.ssh/shortsai_synology
    IdentitiesOnly yes
    StrictHostKeyChecking accept-new
    ProxyJump root@159.255.37.158
```

Теперь можно подключаться:
```powershell
ssh synology-shortsai
```




