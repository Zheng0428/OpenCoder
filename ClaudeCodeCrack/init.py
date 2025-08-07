#!/usr/bin/env python3
"""
多种冒泡排序算法实现
"""


def basic_bubble_sort(arr):
    """
    基础冒泡排序算法
    最简单的实现，没有任何优化
    
    Args:
        arr: 需要排序的数组
        
    Returns:
        排序后的数组
    """
    n = len(arr)
    for i in range(n):
        for j in range(0, n - i - 1):
            if arr[j] > arr[j + 1]:
                arr[j], arr[j + 1] = arr[j + 1], arr[j]
    return arr


def optimized_bubble_sort(arr):
    """
    优化的冒泡排序算法
    包含早期终止优化：如果某次遍历没有发生交换，说明数组已经有序
    
    Args:
        arr: 需要排序的数组
        
    Returns:
        排序后的数组
    """
    n = len(arr)
    for i in range(n):
        swapped = False
        for j in range(0, n - i - 1):
            if arr[j] > arr[j + 1]:
                arr[j], arr[j + 1] = arr[j + 1], arr[j]
                swapped = True
        if not swapped:
            break
    return arr


def cocktail_shaker_sort(arr):
    """
    鸡尾酒排序（双向冒泡排序）
    在每次迭代中，先从左到右，再从右到左进行排序
    对于部分有序的数组效率更高
    
    Args:
        arr: 需要排序的数组
        
    Returns:
        排序后的数组
    """
    n = len(arr)
    swapped = True
    start = 0
    end = n - 1
    
    while swapped:
        swapped = False
        
        # 从左到右
        for i in range(start, end):
            if arr[i] > arr[i + 1]:
                arr[i], arr[i + 1] = arr[i + 1], arr[i]
                swapped = True
        
        if not swapped:
            break
            
        end -= 1
        swapped = False
        
        # 从右到左
        for i in range(end, start, -1):
            if arr[i] < arr[i - 1]:
                arr[i], arr[i - 1] = arr[i - 1], arr[i]
                swapped = True
        
        start += 1
    
    return arr


def boundary_bubble_sort(arr):
    """
    边界优化冒泡排序
    记录最后一次交换的位置，该位置之后的元素已经有序
    
    Args:
        arr: 需要排序的数组
        
    Returns:
        排序后的数组
    """
    n = len(arr)
    while n > 1:
        new_n = 0
        for i in range(1, n):
            if arr[i - 1] > arr[i]:
                arr[i - 1], arr[i] = arr[i], arr[i - 1]
                new_n = i
        n = new_n
    return arr


def recursive_bubble_sort(arr, n=None):
    """
    递归实现的冒泡排序
    每次递归将最大的元素放到正确位置
    
    Args:
        arr: 需要排序的数组
        n: 当前需要排序的元素个数
        
    Returns:
        排序后的数组
    """
    if n is None:
        n = len(arr)
    
    if n == 1:
        return arr
    
    for i in range(n - 1):
        if arr[i] > arr[i + 1]:
            arr[i], arr[i + 1] = arr[i + 1], arr[i]
    
    recursive_bubble_sort(arr, n - 1)
    return arr


def display_menu():
    """显示算法选择菜单"""
    print("\n" + "="*50)
    print("请选择冒泡排序算法:")
    print("="*50)
    print("1. 基础冒泡排序 (Basic Bubble Sort)")
    print("2. 优化冒泡排序 (Optimized Bubble Sort)")
    print("3. 鸡尾酒排序 (Cocktail Shaker Sort)")
    print("4. 边界优化冒泡排序 (Boundary Bubble Sort)")
    print("5. 递归冒泡排序 (Recursive Bubble Sort)")
    print("6. 运行所有算法并比较")
    print("0. 退出")
    print("="*50)


def get_test_array():
    """获取测试数组"""
    print("\n请选择测试数组:")
    print("1. 使用默认数组 [64, 34, 25, 12, 22, 11, 90]")
    print("2. 输入自定义数组")
    print("3. 生成随机数组")
    
    choice = input("请输入选择 (1-3): ")
    
    if choice == "1":
        return [64, 34, 25, 12, 22, 11, 90]
    elif choice == "2":
        try:
            arr_str = input("请输入数组元素，用空格分隔: ")
            return list(map(int, arr_str.split()))
        except ValueError:
            print("输入无效，使用默认数组")
            return [64, 34, 25, 12, 22, 11, 90]
    elif choice == "3":
        import random
        size = int(input("请输入数组大小 (默认10): ") or "10")
        max_val = int(input("请输入最大值 (默认100): ") or "100")
        return [random.randint(1, max_val) for _ in range(size)]
    else:
        return [64, 34, 25, 12, 22, 11, 90]


def run_algorithm(algorithm, arr, name):
    """运行指定的排序算法并显示结果"""
    import time
    
    arr_copy = arr.copy()
    print(f"\n使用 {name}")
    print(f"原数组: {arr_copy}")
    
    start_time = time.perf_counter()
    sorted_array = algorithm(arr_copy)
    end_time = time.perf_counter()
    
    print(f"排序后: {sorted_array}")
    print(f"耗时: {(end_time - start_time) * 1000:.4f} 毫秒")
    
    return end_time - start_time


def compare_all_algorithms(arr):
    """比较所有算法的性能"""
    algorithms = [
        (basic_bubble_sort, "基础冒泡排序"),
        (optimized_bubble_sort, "优化冒泡排序"),
        (cocktail_shaker_sort, "鸡尾酒排序"),
        (boundary_bubble_sort, "边界优化冒泡排序"),
        (recursive_bubble_sort, "递归冒泡排序")
    ]
    
    print("\n" + "="*50)
    print("算法性能比较")
    print("="*50)
    
    results = []
    for algorithm, name in algorithms:
        time_taken = run_algorithm(algorithm, arr, name)
        results.append((name, time_taken))
    
    print("\n" + "="*50)
    print("性能排名（从快到慢）:")
    print("="*50)
    
    results.sort(key=lambda x: x[1])
    for i, (name, time_taken) in enumerate(results, 1):
        print(f"{i}. {name}: {time_taken * 1000:.4f} 毫秒")


def main():
    """主函数，提供交互式菜单"""
    print("欢迎使用冒泡排序算法演示程序！")
    
    while True:
        display_menu()
        
        choice = input("\n请输入您的选择 (0-6): ")
        
        if choice == "0":
            print("感谢使用，再见！")
            break
        
        if choice not in ["1", "2", "3", "4", "5", "6"]:
            print("无效选择，请重试")
            continue
        
        test_array = get_test_array()
        
        if choice == "1":
            run_algorithm(basic_bubble_sort, test_array, "基础冒泡排序")
        elif choice == "2":
            run_algorithm(optimized_bubble_sort, test_array, "优化冒泡排序")
        elif choice == "3":
            run_algorithm(cocktail_shaker_sort, test_array, "鸡尾酒排序")
        elif choice == "4":
            run_algorithm(boundary_bubble_sort, test_array, "边界优化冒泡排序")
        elif choice == "5":
            run_algorithm(recursive_bubble_sort, test_array, "递归冒泡排序")
        elif choice == "6":
            compare_all_algorithms(test_array)
        
        input("\n按回车键继续...")


if __name__ == "__main__":
    main()