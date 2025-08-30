#!/usr/bin/env python3
"""
创建材质的示例脚本

此脚本演示如何创建和应用各种类型的材质
"""

import bpy
import random


def main():
    """
    主函数 - 创建材质
    """
    try:
        # 确保有活动对象
        if not bpy.context.active_object:
            print("没有活动对象，请先选择一个对象")
            return False

        obj = bpy.context.active_object

        # 创建多种材质
        materials = [
            create_glossy_material(),
            create_diffuse_material(),
            create_transparent_material(),
            create_emissive_material(),
            create_metallic_material()
        ]

        # 随机分配材质（如果对象是网格且有多个面）
        if hasattr(obj.data, 'polygons') and len(obj.data.polygons) > 1:
            assign_random_materials(obj, materials)
        else:
            # 分配第一个材质
            if len(obj.data.materials) == 0:
                obj.data.materials.append(materials[0])
            else:
                obj.data.materials[0] = materials[0]

        print(f"材质创建完成，创建了 {len(materials)} 个材质")
        return True

    except Exception as e:
        print(f"材质脚本执行失败: {e}")
        return False


def create_glossy_material():
    """
    创建光泽材质 (Principled BSDF)
    """
    material = bpy.data.materials.new(name="Glossy_Material")

    # 创建节点材质
    material.use_nodes = True
    nodes = material.node_tree.nodes
    links = material.node_tree.links

    # 清除默认节点
    for node in nodes:
        nodes.remove(node)

    # 创建 Principled BSDF 节点
    principled = nodes.new(type='ShaderNodeBsdfPrincipled')
    principled.inputs['Base Color'].default_value = (0.8, 0.1, 0.1, 1.0)
    principled.inputs['Roughness'].default_value = 0.2
    principled.inputs['Metallic'].default_value = 0.0

    # 创建输出节点
    output = nodes.new(type='ShaderNodeOutputMaterial')
    output.location = (400, 0)

    # 连接节点
    links.new(principled.outputs['BSDF'], output.inputs['Surface'])

    return material


def create_diffuse_material():
    """
    创建漫反射材质
    """
    material = bpy.data.materials.new(name="Diffuse_Material")

    material.use_nodes = True
    nodes = material.node_tree.nodes
    links = material.node_tree.links

    # 获取默认节点
    principled = nodes.get("Principled BSDF")
    if principled:
        principled.inputs['Base Color'].default_value = (0.1, 0.8, 0.1, 1.0)
        principled.inputs['Roughness'].default_value = 0.8
        principled.inputs['Metallic'].default_value = 0.0

    return material


def create_transparent_material():
    """
    创建透明材质
    """
    material = bpy.data.materials.new(name="Transparent_Material")

    material.use_nodes = True
    nodes = material.node_tree.nodes
    links = material.node_tree.links

    # 获取默认 Principled BSDF
    principled = nodes.get("Principled BSDF")
    if principled:
        # 设置玻璃参数
        principled.inputs['Base Color'].default_value = (0.8, 0.9, 1.0, 1.0)
        principled.inputs['Roughness'].default_value = 0.0
        principled.inputs['IOR'].default_value = 1.5
        principled.inputs['Transmission'].default_value = 1.0
        principled.inputs['Alpha'].default_value = 0.3

    return material


def create_emissive_material():
    """
    创建自发光材质
    """
    material = bpy.data.materials.new(name="Emissive_Material")

    material.use_nodes = True
    nodes = material.node_tree.nodes
    links = material.node_tree.links

    # 获取默认 Principled BSDF
    principled = nodes.get("Principled BSDF")
    if principled:
        # 设置自发光参数
        principled.inputs['Base Color'].default_value = (0.8, 0.8, 0.2, 1.0)
        principled.inputs['Emission'].default_value = (1.0, 1.0, 0.5, 1.0)
        principled.inputs['Emission Strength'].default_value = 5.0

    return material


def create_metallic_material():
    """
    创建金属材质
    """
    material = bpy.data.materials.new(name="Metallic_Material")

    material.use_nodes = True
    nodes = material.node_tree.nodes
    links = material.node_tree.links

    # 获取默认 Principled BSDF
    principled = nodes.get("Principled BSDF")
    if principled:
        # 设置金属参数
        principled.inputs['Base Color'].default_value = (0.9, 0.9, 0.9, 1.0)
        principled.inputs['Roughness'].default_value = 0.1
        principled.inputs['Metallic'].default_value = 1.0
        principled.inputs['Specular'].default_value = 1.0

    return material


def assign_random_materials(obj, materials):
    """
    为对象的每个面随机分配材质
    """
    try:
        # 为对象添加多个材质槽
        for material in materials:
            obj.data.materials.append(material)

        # 为每个面分配随机材质
        for poly in obj.data.polygons:
            random_material_index = random.randint(0, len(materials) - 1)
            poly.material_index = random_material_index

        print(f"为 {len(obj.data.polygons)} 个面分配了随机材质")

    except Exception as e:
        print(f"随机材质分配失败: {e}")


if __name__ == "__main__":
    main()