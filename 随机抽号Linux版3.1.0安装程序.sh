#!/bin/bash

# 随机抽号信创V3 图形化安装程序
# 版本: 3.1.0
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

# 显示欢迎界面（按回车开始）
show_welcome() {
    whiptail --title "随机抽号信创V3 安装程序" \
        --backtitle "随机抽号信创V3 - 安装向导" \
        --msgbox "欢迎使用随机抽号信创V3 安装程序！\n\n版本: 3.1.0\n开发者: luckynum\n邮箱: 1715250361@qq.com\n\n请按回车键开始安装。" \
        15 60
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
    local desktop_file="$install_dir/随机抽号信创V3.desktop"
    
    cat > "$desktop_file" << EOF
[Desktop Entry]
Name=随机抽号信创V3
Comment=幸运数字随机抽取工具
Exec=$install_dir/lucky-num
Icon=$install_dir/icon.png
Terminal=false
Type=Application
Categories=Utility;
StartupWMClass=lucky-num
EOF
    
    chmod 644 "$desktop_file"
}

# 安装应用到系统
install_to_system() {
    local install_dir="/opt/随机抽号信创V3"
    
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
    echo "正在创建桌面文件..." >> "$LOG_FILE"
    sudo bash -c "cat > '$install_dir/随机抽号信创V3.desktop' << EOF
[Desktop Entry]
Name=随机抽号信创V3
Comment=幸运数字随机抽取工具
Exec=$install_dir/lucky-num
Icon=$install_dir/icon.png
Terminal=false
Type=Application
Categories=Utility;
StartupWMClass=lucky-num
EOF"
    sudo chmod 644 "$install_dir/随机抽号信创V3.desktop"
    
    # 设置权限
    echo "正在设置权限..." >> "$LOG_FILE"
    sudo chown -R root:root "$install_dir" 2>> "$LOG_FILE"
    sudo chmod -R 755 "$install_dir" 2>> "$LOG_FILE"
    
    # 复制到系统快捷方式目录（开始菜单）
    echo "正在创建开始菜单快捷方式..." >> "$LOG_FILE"
    sudo cp "$install_dir/随机抽号信创V3.desktop" "/usr/share/applications/" 2>> "$LOG_FILE"
    sudo chmod 644 "/usr/share/applications/随机抽号信创V3.desktop" 2>> "$LOG_FILE"
    
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
        cp "$install_dir/随机抽号信创V3.desktop" "$DESKTOP_DIR/" 2>> "$LOG_FILE"
        chmod +x "$DESKTOP_DIR/随机抽号信创V3.desktop" 2>> "$LOG_FILE"
        
        # 确保桌面快捷方式图标路径正确
        sed -i "s|Icon=.*|Icon=$install_dir/icon.png|" "$DESKTOP_DIR/随机抽号信创V3.desktop" 2>> "$LOG_FILE"
        
        # 验证桌面快捷方式
        if [ -f "$DESKTOP_DIR/随机抽号信创V3.desktop" ]; then
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
    if [ -f "/usr/share/applications/随机抽号信创V3.desktop" ]; then
        echo "✓ 开始菜单快捷方式创建成功" >> "$LOG_FILE"
    else
        echo "✗ 开始菜单快捷方式创建失败" >> "$LOG_FILE"
    fi
}

# 主安装流程
main_install() {
    local arch=$(detect_arch)
    
    # 创建临时构建目录
    BUILD_DIR="/tmp/lucky-num-build-$$"
    mkdir -p "$BUILD_DIR"
    cd "$BUILD_DIR"
    
    # 步骤1-2：准备环境
    {
        update_progress 1
        sleep 0.5
        update_progress 2
        configure_npm
        sleep 0.5
    } | whiptail --title "随机抽号信创V3 安装程序" \
        --gauge "正在准备安装环境..." 8 60 0
    
    # 步骤3：下载文件
    {
        update_progress 3
        curl -L "https://luckynum.top/online.html" -o "index.html" > /dev/null 2>&1
        curl -L "https://luckynum.top/icon.png" -o "icon.png" > /dev/null 2>&1
        sleep 0.5
    } | whiptail --title "随机抽号信创V3 安装程序" \
        --gauge "正在下载应用文件..." 8 60 0
    
    # 创建package.json
    cat > "package.json" << EOF
{
  "name": "lucky-num",
  "version": "3.1.0",
  "description": "随机抽号信创V3",
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
        update_progress 4
        npm install --no-audit --no-fund > /dev/null 2>&1
    } | whiptail --title "随机抽号信创V3 安装程序" \
        --gauge "正在安装依赖包..." 8 60 0
    
    # 步骤5：配置应用
    {
        update_progress 5
        sleep 1
    } | whiptail --title "随机抽号信创V3 安装程序" \
        --gauge "正在配置应用..." 8 60 0
    
    # 步骤6-7：安装到系统
    {
        update_progress 6
        install_to_system
        sleep 0.5
        update_progress 7
    } | whiptail --title "随机抽号信创V3 安装程序" \
        --gauge "正在安装到系统..." 8 60 0
    
    # 步骤8：完成
    {
        update_progress 8
        sleep 1
    } | whiptail --title "随机抽号信创V3 安装程序" \
        --gauge "正在完成安装..." 8 60 0
    
    # 清理
    cd /
    rm -rf "$BUILD_DIR"
}

# 显示完成界面（使用↑↓键选择）
show_complete() {
    local choice
    
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
    whiptail --title "随机抽号信创V3 安装程序" \
        --backtitle "随机抽号信创V3 - 安装完成" \
        --msgbox "安装已完成！\n\n随机抽号信创V3 已成功安装到您的系统。\n\n✓ 开始菜单快捷方式已创建\n✓ 桌面快捷方式已创建到: $DESKTOP_PATH\n\n按回车键继续..." \
        15 65
    
    # 选择菜单（使用↑↓键选择）
    choice=$(whiptail --title "随机抽号信创V3 安装程序" \
        --backtitle "随机抽号信创V3 - 操作选择" \
        --menu "请选择要执行的操作\n\n提示：使用 [↑] [↓] 键选择，[Enter] 键确认" \
        16 65 3 \
        "1" "立即启动 随机抽号信创V3" \
        "2" "关闭安装程序" \
        3>&1 1>&2 2>&3)
    
    case $choice in
        1)
            /opt/随机抽号信创V3/lucky-num &
            whiptail --title "随机抽号信创V3" \
                --msgbox "应用已启动，请在系统托盘中查看。\n\n按回车键退出安装程序。" \
                10 50
            ;;
        2)
            whiptail --title "随机抽号信创V3" \
                --msgbox "感谢使用随机抽号信创V3！\n\n按回车键退出安装程序。" \
                10 50
            ;;
    esac
}

# 主函数
main() {
    # 检查whiptail
    check_whiptail
    
    # 显示欢迎界面（按回车开始）
    show_welcome || exit 1
    
    # 执行安装
    main_install
    
    # 显示完成界面
    show_complete
    
    clear
    echo -e "${GREEN}安装完成！${NC}"
    echo "你可以在以下位置找到应用："
    echo "  - 开始菜单：随机抽号信创V3"
    echo "  - 桌面快捷方式：随机抽号信创V3"
    echo "  - 安装目录：/opt/随机抽号信创V3"
    echo ""
    echo "日志文件: $LOG_FILE"
    echo "查看日志: cat $LOG_FILE"
    echo ""
    echo "如果桌面没有快捷方式，请手动复制："
    echo "cp /usr/share/applications/随机抽号信创V3.desktop ~/Desktop/"
    echo "或"
    echo "cp /usr/share/applications/随机抽号信创V3.desktop ~/桌面/"
}

# 执行主函数
main "$@"