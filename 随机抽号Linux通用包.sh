#!/bin/bash

# 随机抽号 动态版本安装程序
# 开发者: luckynum
# 邮箱: 1715250361@qq.com

# 日志文件
LOG_FILE="/tmp/lucky-num-install-$(date +%Y%m%d-%H%M%S).log"

# 颜色定义（仅用于日志）
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

# 检查whiptail是否安装
check_whiptail() {
    if ! command -v whiptail &> /dev/null; then
        echo "正在安装 whiptail..."
        sudo apt-get update > /dev/null 2>&1
        sudo apt-get install -y whiptail > /dev/null 2>&1
    fi
}

# 检查网络连接
check_network() {
    local timeout=3
    local target="luckynum.top"
    
    # 先尝试 ping
    if ping -c 1 -W $timeout $target > /dev/null 2>&1; then
        return 0
    fi
    
    # 如果 ping 失败，尝试 curl
    if curl -s --connect-timeout $timeout -I "https://$target" > /dev/null 2>&1; then
        return 0
    fi
    
    return 1
}

# 从网络获取版本号
fetch_version() {
    local version_url="https://luckynum.top/version.txt"
    local version
    
    # 先检查网络
    if ! check_network; then
        whiptail --title "网络错误" \
            --backtitle "随机抽号 - 安装程序" \
            --msgbox "无法连接到 luckynum.top\n\n请检查您的网络连接后重试。" \
            10 50
        return 1
    fi
    
    # 尝试下载版本文件，超时5秒
    version=$(curl -s --connect-timeout 5 "$version_url" 2>/dev/null | tr -d ' \n\r')
    
    # 验证版本号格式 (x.y.z)
    if [[ "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        echo "$version"
        return 0
    else
        whiptail --title "版本获取失败" \
            --backtitle "随机抽号 - 安装程序" \
            --msgbox "无法获取有效的版本号\n\n请检查网络后重试。" \
            10 50
        return 1
    fi
}

# 显示欢迎界面（按回车开始）
show_welcome() {
    local version="$1"
    local major_version="${version%%.*}"
    
    whiptail --title "随机抽号V${major_version} 安装程序" \
        --backtitle "随机抽号 - 安装向导" \
        --msgbox "欢迎使用随机抽号 安装程序！\n\n版本: ${version}\n开发者: luckynum\n邮箱: 1715250361@qq.com\n\n请按回车键开始安装。" \
        15 60
    
    return $?
}

# 显示安装进度
show_progress() {
    local step=$1
    local message=$2
    local percent=$3
    
    echo "XXX"
    echo $percent
    echo "$message"
    echo "XXX"
}

# 更新进度条
update_progress() {
    local step=$1
    local version=$2
    local major_version="${version%%.*}"
    local total_steps=8
    local percent=$((step * 100 / total_steps))
    
    case $step in
        1) show_progress $step "正在检测系统架构..." $percent ;;
        2) show_progress $step "正在准备安装环境..." $percent ;;
        3) show_progress $step "正在下载应用文件..." $percent ;;
        4) show_progress $step "正在安装依赖包..." $percent ;;
        5) show_progress $step "正在配置应用..." $percent ;;
        6) show_progress $step "正在安装到系统..." $percent ;;
        7) show_progress $step "正在创建快捷方式..." $percent ;;
        8) show_progress $step "正在完成安装..." $percent ;;
    esac
}

# 检测系统架构
detect_arch() {
    local arch=$(uname -m)
    case $arch in
        x86_64) echo "amd64" ;;
        aarch64) echo "arm64" ;;
        loongarch64) echo "loong64" ;;
        armv7l|armhf) echo "armv7l" ;;
        *) echo "unknown" ;;
    esac
}

# 配置npm镜像
configure_npm() {
    export ELECTRON_MIRROR="https://npmmirror.com/mirrors/electron/"
    export ELECTRON_BUILDER_BINARIES_MIRROR="https://npmmirror.com/mirrors/electron-builder-binaries/"
    npm config set registry https://registry.npmmirror.com > /dev/null 2>&1
}

# 创建启动脚本
create_launcher() {
    local install_dir="$1"
    local version="$2"
    local major_version="${version%%.*}"
    
    cat > "$install_dir/lucky-num" << 'EOF'
#!/bin/bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$DIR"
ELECTRON_ENABLE_LOGGING=false npx electron main.js > /dev/null 2>&1
EOF
    chmod +x "$install_dir/lucky-num"
}

# 创建桌面文件
create_desktop_file() {
    local install_dir="$1"
    local version="$2"
    local major_version="${version%%.*}"
    local desktop_file="$install_dir/随机抽号V${major_version}.desktop"
    
    cat > "$desktop_file" << EOF
[Desktop Entry]
Name=随机抽号V${major_version}
Comment=随机抽号
Exec=$install_dir/lucky-num
Icon=$install_dir/icon.png
Terminal=false
Type=Application
Categories=Utility;
StartupWMClass=lucky-num
EOF
    
    chmod 644 "$desktop_file"
    echo "$desktop_file"  # 返回文件路径
}

# 安装应用到系统
install_to_system() {
    local version="$1"
    local major_version="${version%%.*}"
    local install_dir="/opt/随机抽号V${major_version}"
    
    # 创建安装目录
    echo "正在创建安装目录..." >> "$LOG_FILE"
    sudo mkdir -p "$install_dir"
    
    # 复制文件
    echo "正在复制文件..." >> "$LOG_FILE"
    sudo cp "$BUILD_DIR"/main.js "$install_dir/" 2>> "$LOG_FILE"
    sudo cp "$BUILD_DIR"/index.html "$install_dir/" 2>> "$LOG_FILE"
    sudo cp "$BUILD_DIR"/icon.png "$install_dir/" 2>> "$LOG_FILE"
    sudo cp -r "$BUILD_DIR/node_modules" "$install_dir/" 2>> "$LOG_FILE"
    
    # 创建启动脚本
    echo "正在创建启动脚本..." >> "$LOG_FILE"
    sudo bash -c "cat > '$install_dir/lucky-num' << 'EOF'
#!/bin/bash
DIR=\"\$( cd \"\$( dirname \"\${BASH_SOURCE[0]}\" )\" && pwd )\"
cd \"\$DIR\"
ELECTRON_ENABLE_LOGGING=false npx electron main.js > /dev/null 2>&1
EOF"
    sudo chmod +x "$install_dir/lucky-num"
    
    # 创建桌面文件
    local desktop_file=$(create_desktop_file "$install_dir" "$version")
    
    # 设置权限
    echo "正在设置权限..." >> "$LOG_FILE"
    sudo chown -R root:root "$install_dir" 2>> "$LOG_FILE"
    sudo chmod -R 755 "$install_dir" 2>> "$LOG_FILE"
    
    # 复制到系统快捷方式目录（开始菜单）
    echo "正在创建开始菜单快捷方式..." >> "$LOG_FILE"
    sudo cp "$desktop_file" "/usr/share/applications/" 2>> "$LOG_FILE"
    sudo chmod 644 "/usr/share/applications/$(basename "$desktop_file")" 2>> "$LOG_FILE"
    
    # 查找桌面目录（处理中文和英文桌面名）
    DESKTOP_DIR=""
    if [ -d "$HOME/桌面" ]; then
        DESKTOP_DIR="$HOME/桌面"
    elif [ -d "$HOME/Desktop" ]; then
        DESKTOP_DIR="$HOME/Desktop"
    elif [ -d "$HOME/ Escritorio" ]; then
        DESKTOP_DIR="$HOME/ Escritorio"
    else
        # 尝试创建桌面目录
        mkdir -p "$HOME/Desktop"
        DESKTOP_DIR="$HOME/Desktop"
    fi
    
    # 复制到桌面
    if [ -n "$DESKTOP_DIR" ]; then
        echo "正在创建桌面快捷方式到: $DESKTOP_DIR" >> "$LOG_FILE"
        cp "$desktop_file" "$DESKTOP_DIR/" 2>> "$LOG_FILE"
        chmod +x "$DESKTOP_DIR/$(basename "$desktop_file")" 2>> "$LOG_FILE"
        
        # 验证桌面快捷方式
        if [ -f "$DESKTOP_DIR/$(basename "$desktop_file")" ]; then
            echo "✓ 桌面快捷方式创建成功" >> "$LOG_FILE"
        else
            echo "✗ 桌面快捷方式创建失败" >> "$LOG_FILE"
        fi
    else
        echo "✗ 无法找到桌面目录" >> "$LOG_FILE"
    fi
    
    # 更新桌面数据库
    if command -v update-desktop-database &> /dev/null; then
        echo "正在更新桌面数据库..." >> "$LOG_FILE"
        sudo update-desktop-database > /dev/null 2>&1
    fi
    
    # 验证开始菜单快捷方式
    if [ -f "/usr/share/applications/$(basename "$desktop_file")" ]; then
        echo "✓ 开始菜单快捷方式创建成功" >> "$LOG_FILE"
    else
        echo "✗ 开始菜单快捷方式创建失败" >> "$LOG_FILE"
    fi
    
    echo "$install_dir"  # 返回安装目录
}

# 主安装流程
main_install() {
    local version="$1"
    local major_version="${version%%.*}"
    local arch=$(detect_arch)
    
    # 创建临时构建目录
    BUILD_DIR="/tmp/lucky-num-build-$$"
    mkdir -p "$BUILD_DIR"
    cd "$BUILD_DIR"
    
    # 步骤1-2：准备环境
    {
        update_progress 1 "$version"
        sleep 0.5
        update_progress 2 "$version"
        configure_npm
        sleep 0.5
    } | whiptail --title "随机抽号V${major_version} 安装程序" \
        --gauge "正在准备安装环境..." 8 60 0
    
    # 步骤3：下载文件
    {
        update_progress 3 "$version"
        curl -L "https://luckynum.top/online.html" -o "index.html" > /dev/null 2>&1
        curl -L "https://luckynum.top/icon.png" -o "icon.png" > /dev/null 2>&1
        sleep 0.5
    } | whiptail --title "随机抽号V${major_version} 安装程序" \
        --gauge "正在下载应用文件..." 8 60 0
    
    # 创建package.json
    cat > "package.json" << EOF
{
  "name": "lucky-num",
  "version": "${version}",
  "description": "随机抽号",
  "main": "main.js",
  "author": "luckynum <1715250361@qq.com>",
  "homepage": "https://luckynum.top",
  "scripts": {
    "start": "electron main.js"
  },
  "dependencies": {
    "electron": "^28.0.0"
  }
}
EOF
    
    # 创建main.js
    cat > "main.js" << 'EOF'
const { app, BrowserWindow } = require('electron');
const path = require('path');

let mainWindow;

function createWindow() {
    mainWindow = new BrowserWindow({
        width: 480,
        height: 600,
        resizable: false,
        autoHideMenuBar: true,
        icon: path.join(__dirname, 'icon.png'),
        webPreferences: {
            nodeIntegration: false,
            contextIsolation: true,
            partition: 'persist:main'
        },
        show: false
    });

    mainWindow.setMenu(null);
    mainWindow.loadFile('index.html');

    mainWindow.once('ready-to-show', () => {
        mainWindow.show();
    });

    mainWindow.on('closed', () => {
        mainWindow = null;
    });
}

app.whenReady().then(createWindow);
app.on('window-all-closed', () => {
    if (process.platform !== 'darwin') app.quit();
});
EOF
    
    # 步骤4：安装依赖
    {
        update_progress 4 "$version"
        npm install --no-audit --no-fund > /dev/null 2>&1
    } | whiptail --title "随机抽号V${major_version} 安装程序" \
        --gauge "正在安装依赖包..." 8 60 0
    
    # 步骤5：配置应用
    {
        update_progress 5 "$version"
        sleep 1
    } | whiptail --title "随机抽号V${major_version} 安装程序" \
        --gauge "正在配置应用..." 8 60 0
    
    # 步骤6-7：安装到系统
    local install_dir
    {
        update_progress 6 "$version"
        install_dir=$(install_to_system "$version")
        sleep 0.5
        update_progress 7 "$version"
    } | whiptail --title "随机抽号V${major_version} 安装程序" \
        --gauge "正在安装到系统..." 8 60 0
    
    # 步骤8：完成
    {
        update_progress 8 "$version"
        sleep 1
    } | whiptail --title "随机抽号V${major_version} 安装程序" \
        --gauge "正在完成安装..." 8 60 0
    
    # 清理
    cd /
    rm -rf "$BUILD_DIR"
    
    echo "$install_dir"  # 返回安装目录
}

# 显示完成界面（使用↑↓键选择）
show_complete() {
    local version="$1"
    local install_dir="$2"
    local major_version="${version%%.*}"
    
    # 获取桌面路径用于显示
    DESKTOP_PATH=""
    if [ -d "$HOME/桌面" ]; then
        DESKTOP_PATH="$HOME/桌面"
    elif [ -d "$HOME/Desktop" ]; then
        DESKTOP_PATH="$HOME/Desktop"
    else
        DESKTOP_PATH="桌面"
    fi
    
    # 显示提示信息
    whiptail --title "随机抽号V${major_version} 安装程序" \
        --backtitle "随机抽号 - 安装完成" \
        --msgbox "安装已完成！\n\n随机抽号V${major_version} 已成功安装到您的系统。\n\n✓ 开始菜单快捷方式已创建\n✓ 桌面快捷方式已创建到: ${DESKTOP_PATH}\n\n安装目录: ${install_dir}\n\n按回车键继续..." \
        18 65
    
    # 选择菜单（使用↑↓键选择）
    choice=$(whiptail --title "随机抽号V${major_version} 安装程序" \
        --backtitle "随机抽号 - 操作选择" \
        --menu "请选择要执行的操作\n\n提示：使用 [↑] [↓] 键选择，[Enter] 键确认" \
        16 65 3 \
        "1" "立即启动 随机抽号V${major_version}" \
        "2" "关闭安装程序" \
        3>&1 1>&2 2>&3)
    
    case $choice in
        1)
            "${install_dir}/lucky-num" &
            whiptail --title "随机抽号V${major_version}" \
                --msgbox "应用已启动，请在系统托盘中查看。\n\n按回车键退出安装程序。" \
                10 50
            ;;
        2)
            whiptail --title "随机抽号V${major_version}" \
                --msgbox "感谢使用随机抽号！\n\n按回车键退出安装程序。" \
                10 50
            ;;
    esac
}

# 主函数
main() {
    # 检查whiptail
    check_whiptail
    
    # 获取版本号（如果失败则退出）
    VERSION=$(fetch_version)
    if [ $? -ne 0 ] || [ -z "$VERSION" ]; then
        exit 1
    fi
    
    MAJOR_VERSION="${VERSION%%.*}"
    
    # 显示欢迎界面（按回车开始）
    show_welcome "$VERSION" || exit 1
    
    # 执行安装
    INSTALL_DIR=$(main_install "$VERSION")
    
    # 显示完成界面
    show_complete "$VERSION" "$INSTALL_DIR"
    
    clear
    echo -e "${GREEN}安装完成！${NC}"
    echo "你可以在以下位置找到应用："
    echo "  - 开始菜单：随机抽号V${MAJOR_VERSION}"
    echo "  - 桌面快捷方式：随机抽号V${MAJOR_VERSION}"
    echo "  - 安装目录：${INSTALL_DIR}"
    echo ""
    echo "日志文件: $LOG_FILE"
    echo "查看日志: cat $LOG_FILE"
    echo ""
    echo "如果桌面没有快捷方式，请手动复制："
    echo "cp /usr/share/applications/随机抽号V${MAJOR_VERSION}.desktop ~/Desktop/"
    echo "或"
    echo "cp /usr/share/applications/随机抽号V${MAJOR_VERSION}.desktop ~/桌面/"
}

# 执行主函数
main "$@"