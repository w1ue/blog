# 有向无环图的 Transitive Reduction 算法


>最近搞了一个类似的需求还蛮有意思的，由于开始样例没有准备充分，导致设计算法的时候思路走偏了，结果写完了才发现问题。赶完需求之后觉得这个算法应该有业界统一的方案，所以整理记录一下。

## 1. 问题描述

删除有向无环图中的跨层冗余依赖关系，可用于依赖关系处理中对非必要依赖关系的简化。给出简单示例如下：

<div  align="center">    
    <img src="../../../imgs/tr_g1.png" width = "400" height = "300" alt="examples" align=center />
</div>

+ **G1** 为原始图，A -> B 和 C，B -> C，从该依赖关系可看出，A 直接依赖了其后代 B 的后代，这里可以 A -> C 的依赖给删掉。

+ **G2** 为删除依赖关系后的图。


## 2. 问题分析
### 2.1 直接法
一种比较暴力且容易想到的想法是，找出每一个节点的非直接依赖节点，遍历每个节点的直接节点，判断节点的非直接节点和直接节点是否有重合，若有，则删除重合项。

<div  align="center">    
    <img src="../../../imgs/tr_g2.png" width = "400" height = "300" alt="examples" align=center />
</div>

在图 **G3** 中，按照上述分析，可以该图做如下处理：
+ 计算每个节点的非直接依赖节点，得到 ```A: {C, E}, B: {E}, C: {} D: {E} E: {}```

+ 遍历每个节点的直接节点，得到 ```A: {B, C, D}, B: {C}, C: {E}, D:{C, E}```

+ 求每个节点的非直接依赖节点和依赖节点的交集，得到 ```A: {C}, D: {E}```，即为需要移除的边



## 3. 算法实现
### 3.1 直接法
```python
def get_redundant_edges(graph):
    undirect_nodes = {}
    for node, real_nodes in graph.items():
        current_undirect_nodes = set()
        for rn in real_nodes:
            queue = [rn]
            while len(queue) > 0:
                current = queue.pop()
                for next in graph[current]:
                    current_undirect_nodes.add(next)
                    queue.append(next)

        undirect_nodes[node] = current_undirect_nodes
    print("非直接依赖：", undirect_nodes)

    remove_edge = set()
    for node, edges in graph.items():
        current_remove_edge = set(edges).intersection(undirect_nodes[node])
        if len(current_remove_edge) > 0:
            remove_edge |= set((node, x) for x in current_remove_edge)

    print("需要移除的边：", remove_edge)
    return remove_edge


if __name__ == '__main__':
    graph = {
        "A": {"B", "C", "D"}, "B": {"C"}, "C": {"E"}, "D": {"C", "E"}, "E": {}
    }

    removed_edge = get_redundant_edges(graph)
    print(removed_edge)

```


## 4. 业界实现


## 参考链接

