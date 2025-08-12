#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Claude项目数据整理脚本
整理.claude目录中的projects数据，并输出为jsonl格式
"""

import json
import os
import re
import hashlib
from datetime import datetime
from pathlib import Path
from typing import Dict, List, Optional, Any
from dataclasses import dataclass, asdict


input_file = '/mnt/bn/tiktok-mm-5/aiic/users/tianyu/OpenCoder/zili/work_dir/sharegpt_training_data/claude_sonnet_4_20250514_20250714_053209.jsonl'
# input_file = '/mnt/bn/tiktok-mm-5/aiic/users/tianyu/organized_projects.jsonl'
data_list_test = []
with open(input_file, 'r', encoding='utf-8') as f:
    for line in f:
        data = json.loads(line)
        data_list_test.append(data)

print(f"读取 {len(data_list_test)} 条数据")

# just for test

@dataclass
class Project:
    """项目数据结构"""
    id: str
    name: str
    description: Optional[str] = None
    created_at: Optional[str] = None
    updated_at: Optional[str] = None
    status: Optional[str] = None
    metadata: Optional[Dict] = None


class ClaudeProjectOrganizer:
    """Claude项目数据整理器"""
    
    def __init__(self, claude_dir: str = ".claude"):
        """
        初始化项目数据整理器
        
        Args:
            claude_dir: .claude目录路径
        """
        self.claude_dir = Path(claude_dir)
        self.projects: Dict[str, Project] = {}
        self.output_file = "organized_projects.jsonl"
    
    def scan_directory(self) -> None:
        """扫描.claude目录结构"""
        if not self.claude_dir.exists():
            print(f"警告: {self.claude_dir} 目录不存在")
            return
        
        print(f"扫描目录: {self.claude_dir}")
        
        # 查找项目相关文件
        project_files = list(self.claude_dir.glob("**/project*.json"))
        project_files.extend(list(self.claude_dir.glob("**/projects.json")))
        
        print(f"找到 {len(project_files)} 个项目文件")
    
    def load_json_file(self, file_path: Path) -> Optional[Dict]:
        """
        安全加载JSON文件
        
        Args:
            file_path: 文件路径
            
        Returns:
            解析后的JSON数据或None
        """
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                return json.load(f)
        except (json.JSONDecodeError, FileNotFoundError, UnicodeDecodeError) as e:
            print(f"无法加载文件 {file_path}: {e}")
            return None

    def load_jsonl_file(self, file_path: Path) -> Optional[List[Dict]]:
        """
        安全加载JSONL文件
        
        Args:
            file_path: JSONL文件路径
            
        Returns:
            解析后的JSON数据列表或None
        """
        try:
            data = []
            with open(file_path, 'r', encoding='utf-8') as f:
                for line_num, line in enumerate(f, 1):
                    line = line.strip()
                    if not line:
                        continue
                    try:
                        json_obj = json.loads(line)
                        data.append(json_obj)
                    except json.JSONDecodeError as e:
                        print(f"警告: 文件 {file_path} 第 {line_num} 行JSON解析错误: {e}")
                        continue
            return data if data else None
        except (FileNotFoundError, UnicodeDecodeError, IOError) as e:
            print(f"无法加载文件 {file_path}: {e}")
            return None
    
    def parse_projects(self, project_data: List[Dict], path_id: str, project_id: str) -> None:
        """
        解析项目数据并转换为ShareGPT格式
        
        Args:
            project_data: 项目中的数据列表
            path_id: 路径ID
            project_id: 项目ID
        """
        print(f"处理项目 {project_id} 中的 {len(project_data)} 条记录")
        
        # 构建UUID到记录的映射
        uuid_map = {}
        for item in project_data:
            if isinstance(item, dict) and 'uuid' in item:
                uuid_map[item['uuid']] = item
        
        # 按依赖关系排序节点
        ordered_nodes = self._sort_by_dependency(project_data, uuid_map)
        print(f"  - 排序后节点: {len(ordered_nodes)} 个")
        if not ordered_nodes: 
            return None
        # 构建对话链并转换为ShareGPT格式
        meta_data = {
            'id': project_id,
            'path_id': path_id
        }

        conversations = self._build_sharegpt_conversations(meta_data, ordered_nodes)
        print(f"  - 生成对话: {len(conversations)} 个")
        
        # 保存转换结果
        self.projects[project_id] = conversations
    
    def _sort_by_dependency(self, project_data: List[Dict], uuid_map: Dict[str, Dict]) -> List[Dict]:
        """按照parentUuid和uuid依赖关系排序节点"""
        # 找到所有根节点（没有parent的节点）
        root_nodes = []
        for item in project_data:
            if isinstance(item, dict) and 'uuid' in item:
                if not item.get('parentUuid'):
                    root_nodes.append(item)
        
        # 递归构建有序列表
        ordered = []
        visited = set()
        
        def dfs_order(node):
            if node['uuid'] in visited:
                return
            visited.add(node['uuid'])
            ordered.append(node)
            
            # 找到当前节点的所有子节点并递归处理
            for item in project_data:
                if isinstance(item, dict) and item.get('parentUuid') == node['uuid']:
                    dfs_order(item)
        
        # 从所有根节点开始DFS
        for root in root_nodes:
            dfs_order(root)
        
        return ordered
    
    def _build_sharegpt_conversations(self, meta_data, ordered_nodes: List[Dict]) -> List[Dict]:
        """将有序节点转换为ShareGPT格式的对话"""
        system_prompt = data_list_test[-1]['conversations'][0]
        conversations = [] # ['text', 'tool_use', 'tool_result', 'thinking']
        current_conversation = [system_prompt]  # if 'toolUseResult' in node.keys():
        
        use_models = []

        for node in ordered_nodes:
            # 检查是否有message字段且包含role
            if 'message' in node and isinstance(node['message'], dict):
                message = node['message']
                role = message.get('role')
                
                if role not in ['user', 'assistant']:
                    continue
                    
                if isinstance(message.get('content'), list):
                    value = message.get('content', [])
                    use_model = message.get('model')
                    if use_model not in use_models and use_model:
                        use_models.append(use_model)
                    if 'toolUseResult' in node.keys():
                        value[-1]['toolUseResult'] = node['toolUseResult']
                else:
                    value = [{
                        'type': 'text',
                        'text': message['content']
                    }]
                
                # 构建ShareGPT格式的消息
                from_role = 'human' if role == 'user' else 'gpt'
                
                # 检查是否需要合并连续的相同角色消息
                if current_conversation and current_conversation[-1]['from'] == from_role:
                    # 合并到上一个相同角色的消息
                    current_conversation[-1]['value'].extend(value)
                else:
                    # 创建新消息
                    sharegpt_message = {
                        'from': from_role,
                        'value': value
                    }
                    
                    current_conversation.append(sharegpt_message)
        
        # 保存最后一个对话
        if current_conversation:
            meta_data['model'] = use_models
            meta_data['timestamp'] = node['timestamp']
            meta_data['conversation_turns'] = len(current_conversation)
            conversations.append({
                'conversations': current_conversation,
                'meta_data': meta_data
            })
        
        return conversations
    
    
    def process_projects(self) -> None:
        """处理项目数据"""
        print("处理项目数据...")
        print(f"共找到 {len(self.projects)} 个项目")
    
    def load_all_data(self) -> None:
        """加载所有项目数据"""
        print("加载Claude项目数据...")
        
        # 扫描目录
        self.scan_directory()
        
        # 加载JSONL项目数据
        projects_dir = self.claude_dir / "projects"
        if projects_dir.exists():
            for path_dir in projects_dir.iterdir():
                if path_dir.is_dir():
                    # 提取路径ID（目录名）
                    path_id = path_dir.name
                    print(f"处理路径ID: {path_id}")
                    
                    # 查找该目录下的所有JSONL文件
                    for file_path in path_dir.glob("*.jsonl"):
                        # 提取项目ID（文件名去掉.jsonl后缀）
                        project_id = file_path.stem
                        print(f"加载项目文件: {file_path} (路径ID: {path_id}, 项目ID: {project_id})")
                        
                        data_list = self.load_jsonl_file(file_path)
                        if data_list:
                            # 每个JSONL文件代表一个项目，传递完整的数据列表进行关系处理
                            self.parse_projects(data_list, path_id, project_id)
    
    def export_to_jsonl(self, output_file: str = None) -> None:
        """
        导出ShareGPT格式数据为JSONL格式
        
        Args:
            output_file: 输出文件名
        """
        if output_file:
            self.output_file = output_file
        
        print(f"导出ShareGPT格式数据到: {self.output_file}")
        
        with open(self.output_file, 'w', encoding='utf-8') as f:
            total_conversations = 0
            # 导出所有对话数据
            for project_id, conversations in self.projects.items():
                if isinstance(conversations, list):
                    for conversation in conversations:
                        f.write(json.dumps(conversation, ensure_ascii=False) + '\n')
                        total_conversations += 1
            
            print(f"共导出 {total_conversations} 个对话")
    
    def print_summary(self) -> None:
        """打印整理结果摘要"""
        print("\n" + "="*60)
        print("ShareGPT数据整理摘要")
        print("="*60)
        print(f"处理项目数: {len(self.projects)}")
        
        # 统计对话信息
        if self.projects:
            total_conversations = 0
            total_turns = 0
            project_models = set()
            
            for project_id, conversations in self.projects.items():
                if isinstance(conversations, list):
                    total_conversations += len(conversations)
                    for conv in conversations:
                        if 'conversations' in conv:
                            total_turns += len(conv['conversations'])
                        if 'meta_data' in conv and 'model' in conv['meta_data']:
                            models = conv['meta_data']['model']
                            if isinstance(models, list):
                                project_models.update(models)
            
            print(f"总对话数: {total_conversations}")
            print(f"总对话轮次: {total_turns}")
            if total_conversations > 0:
                print(f"平均每个对话轮次: {total_turns/total_conversations:.1f}")
            
            if project_models:
                print(f"\n使用的模型:")
                for model in sorted(project_models):
                    print(f"  • {model}")
        
        print(f"\n输出文件: {self.output_file}")
        print("="*60)
    
    def organize(self, output_file: str = None) -> None:
        """
        执行完整的项目数据整理流程
        
        Args:
            output_file: 输出文件名
        """
        print("开始整理Claude项目数据...")
        
        # 加载所有数据
        self.load_all_data()
        
        # 处理项目数据
        self.process_projects()
        
        # 导出数据
        self.export_to_jsonl(output_file)
        
        # 打印摘要
        self.print_summary()
        
        print("项目数据整理完成！")



def main():
    """主函数"""
    import argparse
    parser = argparse.ArgumentParser(description='整理Claude Code log数据')
    parser.add_argument(
        '--claude-dir', 
        default='/mnt/bn/tiktok-mm-5/aiic/users/tianyu/claude_log',
        help='Claude数据目录路径 (默认: /mnt/bn/tiktok-mm-5/aiic/users/tianyu/claude_log)'
    )
    parser.add_argument(
        '--output', 
        default='/mnt/bn/tiktok-mm-5/aiic/users/tianyu/OpenCoder/data/organized_projects.jsonl',
        help='输出文件名 (默认: organized_projects.jsonl)'
    )
    
    args = parser.parse_args()

    organizer = ClaudeProjectOrganizer(args.claude_dir)
    
    try:
        organizer.organize(args.output)
    except KeyboardInterrupt:
        print("\n用户中断操作")
    except Exception as e:
        print(f"错误: {e}")


if __name__ == "__main__":
    main()