#当你看到这个页面，说明由于权限不足，所以安装并没有开始。请认真查看安装方法（https://luckynum.top/安装步骤.png）。


































#!/bin/bash

# 随机抽号 图形化安装程序
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
    
    if ping -c 1 -W $timeout $target > /dev/null 2>&1; then
        return 0
    fi
    
    if curl -s --connect-timeout $timeout -I "https://$target" > /dev/null 2>&1; then
        return 0
    fi
    
    return 1
}

# 从网络获取版本号
fetch_version() {
    local version_url="https://luckynum.top/version.txt"
    local version
    
    if ! check_network; then
        whiptail --title "网络错误" \
            --msgbox "无法连接到 luckynum.top\n\n将使用默认版本 3.1.0\n\n请检查网络后重试。" \
            12 50
        echo "3.1.0"
        return 0
    fi
    
    version=$(curl -s --connect-timeout 5 "$version_url" 2>/dev/null | tr -d ' \n\r')
    
    if [[ "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        echo "$version"
        return 0
    else
        whiptail --title "版本获取失败" \
            --msgbox "无法获取有效的版本号\n\n将使用默认版本 3.1.0" \
            10 50
        echo "3.1.0"
        return 0
    fi
}

# 检查是否已安装
check_installed() {
    local version="$1"
    local install_dir="/opt/随机抽号V${version%%.*}"
    
    [ -d "$install_dir" ]
}

# 显示主菜单
show_main_menu() {
    local version="$1"
    local major="${version%%.*}"
    
    if check_installed "$version"; then
        whiptail --title "随机抽号V${major} 安装程序" \
            --menu "检测到已安装，请选择操作：" \
            15 60 2 \
            "1" "重新安装" \
            "2" "卸载程序" \
            3>&1 1>&2 2>&3
    else
        whiptail --title "随机抽号V${major} 安装程序" \
            --menu "请选择操作：" \
            12 50 1 \
            "1" "安装程序" \
            3>&1 1>&2 2>&3
    fi
}

# 卸载程序
uninstall_app() {
    local version="$1"
    local major="${version%%.*}"
    local install_dir="/opt/随机抽号V${major}"
    
    whiptail --title "确认卸载" \
        --yesno "确定要卸载随机抽号V${major}吗？" \
        10 50 || return 1
    
    {
        echo "20"
        echo "XXX"
        echo "正在删除快捷方式..."
        echo "XXX"
        rm -f "$HOME/桌面/随机抽号V${major}.desktop" 2>/dev/null
        rm -f "$HOME/Desktop/随机抽号V${major}.desktop" 2>/dev/null
        sudo rm -f "/usr/share/applications/随机抽号V${major}.desktop" 2>/dev/null
        sleep 0.5
        
        echo "60"
        echo "XXX"
        echo "正在删除应用程序..."
        echo "XXX"
        sudo rm -rf "$install_dir" 2>/dev/null
        sleep 0.5
        
        echo "100"
        echo "XXX"
        echo "卸载完成！"
        echo "XXX"
        sleep 0.5
    } | whiptail --title "随机抽号V${major} 卸载程序" \
        --gauge "正在卸载，请稍候..." 8 60 0
    
    whiptail --title "卸载完成" --msgbox "随机抽号V${major} 已成功卸载。" 8 40
}

# 显示欢迎界面
show_welcome() {
    local version="$1"
    local major="${version%%.*}"
    
    whiptail --title "随机抽号V${major} 安装程序" \
        --backtitle "随机抽号 - 安装向导" \
        --msgbox "欢迎使用随机抽号 安装程序！\n\n版本: ${version}\n开发者: luckynum\n邮箱: 1715250361@qq.com\n\n请按回车键开始安装。" \
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
    local total_steps=5
    local percent=$((step * 100 / total_steps))
    
    case $step in
        1) show_progress $step "正在下载应用文件..." $percent ;;
        2) show_progress $step "正在安装依赖包..." $percent ;;
        3) show_progress $step "正在安装到系统..." $percent ;;
        4) show_progress $step "正在创建快捷方式..." $percent ;;
        5) show_progress $step "正在完成安装..." $percent ;;
    esac
}

# 配置npm镜像
configure_npm() {
    export ELECTRON_MIRROR="https://npmmirror.com/mirrors/electron/"
    export ELECTRON_BUILDER_BINARIES_MIRROR="https://npmmirror.com/mirrors/electron-builder-binaries/"
    npm config set registry https://registry.npmmirror.com > /dev/null 2>&1
}

# 安装应用到系统
install_to_system() {
    local version="$1"
    local major="${version%%.*}"
    local install_dir="/opt/随机抽号V${major}"
    local build_dir="$2"
    
    # 如果已存在，先删除
    [ -d "$install_dir" ] && sudo rm -rf "$install_dir"
    
    # 创建安装目录
    sudo mkdir -p "$install_dir"
    
    # 复制文件
    sudo cp "$build_dir"/main.js "$install_dir/" 2>/dev/null
    sudo cp "$build_dir"/index.html "$install_dir/" 2>/dev/null
    sudo cp "$build_dir"/icon.png "$install_dir/" 2>/dev/null
    sudo cp -r "$build_dir/node_modules" "$install_dir/" 2>/dev/null
    
    # 创建启动脚本
    sudo bash -c "cat > '${install_dir}/lucky-num' << 'EOF'
#!/bin/bash
cd ${install_dir}
# 设置窗口类名和应用名称
ELECTRON_APP_NAME=\"随机抽号V${major}\"
npx electron main.js
EOF"
    sudo chmod +x "${install_dir}/lucky-num"
    
    # 创建桌面文件 - 添加 StartupWMClass 确保任务栏图标正确
    sudo bash -c "cat > '${install_dir}/随机抽号V${major}.desktop' << EOF
[Desktop Entry]
Name=随机抽号V${major}
Comment=随机抽号
Exec=${install_dir}/lucky-num
Icon=${install_dir}/icon.png
Terminal=false
Type=Application
Categories=Utility;
StartupWMClass=随机抽号V${major}
EOF"
    
    # 设置权限
    sudo chmod 644 "${install_dir}/随机抽号V${major}.desktop"
    
    # 复制到系统快捷方式目录
    sudo cp "${install_dir}/随机抽号V${major}.desktop" "/usr/share/applications/" 2>/dev/null
    
    # 复制到桌面
    if [ -d "$HOME/桌面" ]; then
        cp "/usr/share/applications/随机抽号V${major}.desktop" "$HOME/桌面/" 2>/dev/null
        chmod +x "$HOME/桌面/随机抽号V${major}.desktop" 2>/dev/null
    elif [ -d "$HOME/Desktop" ]; then
        cp "/usr/share/applications/随机抽号V${major}.desktop" "$HOME/Desktop/" 2>/dev/null
        chmod +x "$HOME/Desktop/随机抽号V${major}.desktop" 2>/dev/null
    fi
    
    # 更新桌面数据库
    command -v update-desktop-database >/dev/null && sudo update-desktop-database >/dev/null 2>&1
}

# 主安装流程
main_install() {
    local version="$1"
    local major="${version%%.*}"
    
    # 创建临时构建目录
    BUILD_DIR="/tmp/lucky-num-build-$$"
    mkdir -p "$BUILD_DIR"
    cd "$BUILD_DIR"
    
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
    
    # 创建main.js - 修复图标显示问题
    cat > "main.js" << 'EOF'
const { app, BrowserWindow } = require('electron');
const path = require('path');

let mainWindow;

function createWindow() {
    // 获取版本号
    const version = app.getVersion();
    const major = version.split('.')[0];
    
    mainWindow = new BrowserWindow({
        width: 480,
        height: 600,
        resizable: false,
        autoHideMenuBar: true,
        icon: path.join(__dirname, 'icon.png'),
        title: `随机抽号V${major}`,  // 设置窗口标题
        webPreferences: {
            nodeIntegration: false,
            contextIsolation: true,
            partition: 'persist:main'
        },
        show: false
    });

    // 设置应用名称（用于任务栏）
    app.setName(`随机抽号V${major}`);
    
    mainWindow.setMenu(null);
    mainWindow.loadFile('index.html');

    mainWindow.once('ready-to-show', () => {
        mainWindow.show();
    });

    mainWindow.on('closed', () => {
        mainWindow = null;
    });
}

app.whenReady().then(() => {
    createWindow();

    app.on('activate', () => {
        if (BrowserWindow.getAllWindows().length === 0) {
            createWindow();
        }
    });
});

app.on('window-all-closed', () => {
    if (process.platform !== 'darwin') {
        app.quit();
    }
});
EOF
    
    # 配置npm镜像
    configure_npm
    
    # 步骤1：下载文件
    {
        update_progress 1
        curl -L "https://luckynum.top/online.html" -o "index.html" > /dev/null 2>&1
        curl -L "https://luckynum.top/icon.png" -o "icon.png" > /dev/null 2>&1
        sleep 0.5
    } | whiptail --title "随机抽号V${major} 安装程序" \
        --gauge "正在下载应用文件..." 8 60 0
    
    # 步骤2：安装依赖
    {
        update_progress 2
        npm install --no-audit --no-fund > /dev/null 2>&1
        sleep 0.5
    } | whiptail --title "随机抽号V${major} 安装程序" \
        --gauge "正在安装依赖包..." 8 60 0
    
    # 步骤3：安装到系统
    {
        update_progress 3
        install_to_system "$version" "$BUILD_DIR"
        sleep 0.5
    } | whiptail --title "随机抽号V${major} 安装程序" \
        --gauge "正在安装到系统..." 8 60 0
    
    # 步骤4：创建快捷方式
    {
        update_progress 4
        sleep 0.5
    } | whiptail --title "随机抽号V${major} 安装程序" \
        --gauge "正在创建快捷方式..." 8 60 0
    
    # 步骤5：完成
    {
        update_progress 5
        sleep 0.5
    } | whiptail --title "随机抽号V${major} 安装程序" \
        --gauge "正在完成安装..." 8 60 0
    
    # 清理
    cd /
    rm -rf "$BUILD_DIR"
}

# 显示完成界面
show_complete() {
    local version="$1"
    local major="${version%%.*}"
    local install_dir="/opt/随机抽号V${major}"
    
    # 获取桌面路径
    local desktop_path="$HOME/桌面"
    [ ! -d "$desktop_path" ] && desktop_path="$HOME/Desktop"
    
    whiptail --title "随机抽号V${major} 安装程序" \
        --msgbox "安装已完成！\n\n随机抽号V${major} 已成功安装到您的系统。\n\n✓ 开始菜单快捷方式已创建\n✓ 桌面快捷方式已创建到: ${desktop_path}\n\n安装目录: ${install_dir}\n\n按回车键继续..." \
        18 65
    
    local choice=$(whiptail --title "随机抽号V${major} 安装程序" \
        --menu "请选择要执行的操作\n\n提示：使用 [↑] [↓] 键选择，[Enter] 键确认" \
        16 65 2 \
        "1" "立即启动 随机抽号V${major}" \
        "2" "关闭安装程序" \
        3>&1 1>&2 2>&3)
    
    if [ "$choice" = "1" ]; then
        "${install_dir}/lucky-num" &
        whiptail --title "随机抽号V${major}" \
            --msgbox "应用已启动，请在系统托盘中查看。\n\n按回车键退出安装程序。" \
            10 50
    fi
}

# 主函数
main() {
    # 检查whiptail
    check_whiptail
    
    # 获取版本号
    VERSION=$(fetch_version)
    MAJOR="${VERSION%%.*}"
    
    # 显示主菜单
    CHOICE=$(show_main_menu "$VERSION")
    [ -z "$CHOICE" ] && exit 0
    
    case $CHOICE in
        1)
            show_welcome "$VERSION" || exit 1
            main_install "$VERSION"
            show_complete "$VERSION"
            ;;
        2)
            uninstall_app "$VERSION"
            ;;
    esac
    
    clear
    if [ "$CHOICE" = "1" ]; then
        echo -e "${GREEN}安装完成！${NC}"
        echo "你可以在以下位置找到应用："
        echo "  - 开始菜单：随机抽号V${MAJOR}"
        echo "  - 桌面快捷方式：随机抽号V${MAJOR}"
        echo "  - 安装目录：/opt/随机抽号V${MAJOR}"
        echo ""
        echo "日志文件: $LOG_FILE"
    fi
}

# 执行主函数
main "$@"