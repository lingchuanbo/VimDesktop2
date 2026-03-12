import os
import psutil
import subprocess
import time
import threading
import sys

def taskKill(imageName):
    # cmdPrefix = 'taskkill /F /IM '
    cmdPrefix = r'pskill64.exe '
    cmd = cmdPrefix + imageName
    os.system(cmd)
 
def wait_for_exit():
    input("按回车键立即退出...\n")  # 会阻塞在这里等待输入
    print("用户选择退出...")
    sys.exit()
 
if __name__ == '__main__':
    # 打开文件
    imageNames=[]
    # imageNames = [line.strip() for line in lines]
    
    with open("closeAllExit.ini", "r") as f:
        # 读取文件中的所有行
        lines = f.readlines()
    # 去掉换行字符
    lines = [line.strip() for line in lines]

    # 进程数组
    for line in lines:
        imageNames.append(line)

    for imageName in imageNames:
        for proc in psutil.process_iter():
            try:
                if proc.name() == imageName:
                    print('进程 %s 正在运行' % imageName)
                    taskKill(imageName)
                    break
            except (psutil.NoSuchProcess, psutil.AccessDenied, psutil.ZombieProcess):
                pass
        else:
            print('进程 %s 未找到' % imageName)
            
    print("powershell执行中...")    
     
    subprocess.run(["powershell", "-Command", "Set-ExecutionPolicy RemoteSigned -Scope CurrentUser"], check=True)
    subprocess.run(["powershell", "-File", "closeAllExit.ps1"], check=True)
    
    print("程序将在3秒后自动退出...")

    # 启动一个线程等待用户输入
    exit_thread = threading.Thread(target=wait_for_exit)
    exit_thread.daemon = True  # 设置为守护线程
    exit_thread.start()

    # 主线程等待3秒
    time.sleep(1)
    print("\n3秒时间到，程序退出...")
    sys.exit()
    print("处理完毕")