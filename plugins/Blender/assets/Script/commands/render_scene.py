#!/usr/usr/env python3
"""
渲染当前场景的脚本

此脚本演示如何配置渲染设置并执行渲染
"""

import bpy
import os
from datetime import datetime


def main():
    """
    主函数 - 渲染场景
    """
    try:
        print("开始渲染场景...")

        # 配置渲染设置
        setup_render_settings()

        # 设置输出路径
        setup_output_path()

        # 执行渲染
        render_result = execute_render()

        if render_result:
            print("场景渲染完成!")
            return True
        else:
            print("渲染失败")
            return False

    except Exception as e:
        print(f"渲染脚本执行失败: {e}")
        return False


def setup_render_settings():
    """
    配置渲染设置
    """
    try:
        # 获取渲染设置
        render = bpy.context.scene.render

        # 设置渲染引擎
        render.engine = 'CYCLES'  # 或 'BLENDER_EEVEE'

        # 设置分辨率
        render.resolution_x = 1920
        render.resolution_y = 1080
        render.resolution_percentage = 100

        # 设置帧范围
        render.frame_start = bpy.context.scene.frame_start
        render.frame_end = bpy.context.scene.frame_end

        # Cycles 特定设置
        if render.engine == 'CYCLES':
            cycles = bpy.context.scene.cycles

            # 设置采样
            cycles.samples = 128
            cycles.preview_samples = 16

            # 设置设备 (GPU/CPU)
            cycles.device = 'GPU'

            # 设置软件渲染预设
            bpy.context.preferences.addons['cycles'].preferences.compute_device_type = 'CUDA'

        print("渲染设置配置完成")

    except Exception as e:
        print(f"配置渲染设置失败: {e}")


def setup_output_path():
    """
    设置输出路径
    """
    try:
        # 获取当前场景名称
        scene_name = bpy.context.scene.name
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")

        # 创建输出文件名格式
        output_filename = f"{scene_name}_{timestamp}_####"

        # 设置输出路径
        render = bpy.context.scene.render

        # 使用相对路径
        script_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
        output_dir = os.path.join(script_dir, "render_output")

        # 确保输出目录存在
        if not os.path.exists(output_dir):
            os.makedirs(output_dir)

        # 设置输出文件路径
        render.filepath = os.path.join(output_dir, output_filename)

        # 设置文件格式
        render.image_settings.file_format = 'PNG'
        render.image_settings.color_mode = 'RGBA'

        print(f"输出路径设置完成: {render.filepath}")

    except Exception as e:
        print(f"设置输出路径失败: {e}")


def execute_render():
    """
    执行渲染操作
    """
    try:
        # 检查是否有动画
        frame_start = bpy.context.scene.frame_start
        frame_end = bpy.context.scene.frame_end

        if frame_end > frame_start:
            # 渲染动画
            print(f"渲染动画: 帧 {frame_start} 到 {frame_end}")
            bpy.ops.render.render(animation=True)
        else:
            # 渲染单帧
            print(f"渲染单帧: 帧 {frame_start}")
            bpy.ops.render.render(write_still=True)

        print("渲染执行完成")
        return True

    except Exception as e:
        print(f"执行渲染失败: {e}")
        return False


if __name__ == "__main__":
    main()