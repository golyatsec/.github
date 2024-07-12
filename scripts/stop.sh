#!/bin/bash

# Log dosyası yolu
LOG_FILE="/etc/Script/stop.log"
CONTAINER_NAME="retmes-mongodb-1"
KONZEK_APPS_DIR="/var/apps/konzek"

# Log dosyasına tarih yazma fonksiyonu
log_date() {
    echo "$(date '+%Y-%m-%d %H:%M:%S')" >> "$LOG_FILE"
}

# Log dosyasına mesaj yazma fonksiyonu
log_message() {
    echo "$1" >> "$LOG_FILE"
}

# Log dosyasına komut çıktısı yazma fonksiyonu
log_command_output() {
    echo "$1" >> "$LOG_FILE"
}

# Scriptin başlangıcında tarih bilgisini log dosyasına yaz
log_date

# whoami çıktısını log dosyasına yaz
WHOAMI_OUTPUT=$(whoami)
log_message "Current user: $WHOAMI_OUTPUT"

# Root değilse root kullanıcısına geç
if [ "$WHOAMI_OUTPUT" != "root" ]; then
    log_message "Switching to root user..."
    sudo -i bash << EOF
    log_message "Now running as root."
EOF
fi

# İstenen klasöre geçiş yapma fonksiyonu
change_directory() {
    if [ -d "$KONZEK_APPS_DIR/retmes" ]; then
        cd "$KONZEK_APPS_DIR/retmes"
        log_message "Current directory: $(pwd)"
    elif [ -d "$KONZEK_APPS_DIR/retgate" ]; then
        cd "$KONZEK_APPS_DIR/retgate"
        log_message "Current directory: $(pwd)"
    else
        log_message "retmes veya retgate klasörü bulunamadı. Script sonlandırılıyor."
        exit 1
    fi
}

# İstenen klasöre geçiş yap
change_directory

# Docker container list çıktısını log dosyasına yazdır
log_message "Docker container list output before 'docker-compose up -d':"
docker ps --format '{{.Names}}\t{{.Image}}\t{{.Status}}' | tee -a "$LOG_FILE"

# Retmes'i durdur, $CONTAINER_NAME down olana kadar bekle.
stop_retmes(){
    change_directory
    log_message "Running 'docker compose down' command..."
    docker compose -f $KONZEK_APPS_DIR/retmes/docker-compose.yml down &> /dev/null
    while true; do
        IS_CONTAINER_RUNNING=$(docker inspect --format "{{.State.Running}}" "$CONTAINER_NAME" 2>/dev/null)
        if [ "$IS_CONTAINER_RUNNING" != "true" ]; then
            echo -e "Container $CONTAINER_NAME is down! " | tee -a "$LOG_FILE"
            break
        else
            echo -e "Waiting for container $CONTAINER_NAME to be down... " | tee -a "$LOG_FILE"
            sleep 1
        fi
    done
}
stop_retmes

# Bekleme süresi
log_message "Waiting for 2 seconds after 'docker-compose up -d'..."
sleep 2

# Docker container list çıktısını tekrar log dosyasına yazdır
log_message "Docker container list output after 'docker-compose up -d':"
docker ps --format '{{.Names}}\t{{.Image}}\t{{.Status}}' | tee -a "$LOG_FILE"

# Tarihi tekrar log dosyasına yaz
log_date

# Log dosyasına iki satır boşluk ekleyin
echo "" >> "$LOG_FILE"
echo "" >> "$LOG_FILE"

