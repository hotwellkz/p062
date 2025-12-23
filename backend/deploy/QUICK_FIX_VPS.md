# 🚀 Быстрое исправление и запуск на VPS

## Проблема
Файл скопирован с Windows и имеет CRLF окончания строк, что вызывает ошибки в Linux.

## ✅ Решение - Выполните на VPS

Если вы уже подключены к VPS (ssh root@159.255.37.158), выполните:

```bash
# 1. Исправляем окончания строк
sed -i 's/\r$//' /root/synology-port-forward.sh

# 2. Устанавливаем права на выполнение
chmod +x /root/synology-port-forward.sh

# 3. Запускаем скрипт
bash /root/synology-port-forward.sh
```

## 🔧 Автоматическое решение

### Вариант 1: PowerShell скрипт (с вашего компьютера)

```powershell
cd C:\Users\studo\Downloads\p039-master\p039-master
.\backend\deploy\fix_and_deploy_vps.ps1
```

### Вариант 2: Bash скрипт (если есть Git Bash)

```bash
cd /c/Users/studo/Downloads/p039-master/p039-master
bash backend/deploy/copy_and_fix_vps.sh
```

### Вариант 3: Одна команда из PowerShell

```powershell
cd C:\Users\studo\Downloads\p039-master\p039-master
scp backend\vps\synology-port-forward.sh root@159.255.37.158:/root/
ssh root@159.255.37.158 "sed -i 's/\r`$//' /root/synology-port-forward.sh && chmod +x /root/synology-port-forward.sh && bash /root/synology-port-forward.sh"
```

## 📝 Что делать прямо сейчас

**Если вы уже на VPS (видите приглашение `root@vm3737624:~#`):**

1. Нажмите `Ctrl+C` чтобы прервать текущую команду (если она висит)
2. Выполните:
   ```bash
   sed -i 's/\r$//' /root/synology-port-forward.sh
   chmod +x /root/synology-port-forward.sh
   bash /root/synology-port-forward.sh
   ```

**Если вы не на VPS, подключитесь и выполните команды выше.**

---

**После выполнения скрипт должен запуститься успешно! 🎉**





