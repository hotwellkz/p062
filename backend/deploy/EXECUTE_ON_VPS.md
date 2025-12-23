# 🚀 Выполните это на VPS

## Вы уже подключены к VPS?

Если вы видите приглашение `root@vm3737624:~#`, выполните эти команды:

```bash
# 1. Исправьте окончания строк
sed -i 's/\r$//' /root/synology-port-forward.sh

# 2. Установите права
chmod +x /root/synology-port-forward.sh

# 3. Запустите скрипт
bash /root/synology-port-forward.sh
```

## Или скопируйте и запустите готовый скрипт

**С вашего компьютера (в новом окне PowerShell):**

```powershell
cd C:\Users\studo\Downloads\p039-master\p039-master
scp backend\deploy\fix_on_vps.sh root@159.255.37.158:/root/
```

**Затем на VPS:**

```bash
bash /root/fix_on_vps.sh
```

## Или выполните всё одной командой на VPS

```bash
sed -i 's/\r$//' /root/synology-port-forward.sh && chmod +x /root/synology-port-forward.sh && bash /root/synology-port-forward.sh
```

---

**Это должно решить проблему! 🎉**





