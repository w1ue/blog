# 有向无环图的 Transitive Reduction 算法


>最近搞了一个类似的需求还蛮有意思的，由于开始样例没有准备充分，导致设计算法的时候思路走偏了，结果写完了才发现问题。赶完需求之后觉得这个算法应该有业界统一的方案，所以整理记录一下。

## 1. 问题描述

删除有向无环图中的跨层冗余依赖关系，可用于依赖关系处理中对非必要依赖关系的简化。对于 Transitive Reduction 的专业解释，可以参考链接[1]，给出简单示例如下：

<div  align="center">    
    <img src="../../../imgs/tr_g1.png" width = "400" height = "300" alt="examples" align=center />
</div>

+ **G1** 为原始图，A -> B 和 C，B -> C，从该依赖关系可看出，A 直接依赖了其后代 B 的后代，这里可以 A -> C 的依赖给删掉。

+ **G2** 为删除依赖关系后的图。


## 2. 问题分析

下面将针对 **G3** 所示的图给出两个算法，直接法和拓扑排序法。

<div  align="center">    
    <img src="../../../imgs/tr_g2.png" width = "400" height = "300" alt="examples" align=center />
</div>

### 2.1 直接法

一种比较暴力且容易想到的想法是，找出每一个节点的非直接依赖节点，遍历每个节点的直接节点，判断节点的非直接节点和直接节点是否有重合，若有，则删除重合项。

在图 **G3** 中，按照上述分析，可以该 DAG 做如下处理：
+ 计算每个节点的非直接依赖节点，得到 ```A: {C, E}, B: {E}, C: {} D: {E} E: {}```

+ 遍历每个节点的直接节点，得到 ```A: {B, C, D}, B: {C}, C: {E}, D:{C, E}```

+ 求每个节点的非直接依赖节点和依赖节点的交集，得到 ```A: {C}, D: {E}```，即为需要移除的边

### 2.2 拓扑排序法

该方法是在 stackoverflow 上面一个关于该算法的回答上找到了一个评论，由于无法下载到原始论文[3]，所以把这篇博客[2]看了一遍，大致整理一下思路写在这里。

对于该问题，一种可行的思路（方案一）如下：

+ 遍历 DAG 中的每一条边，start -> end

+ 判断是否存在一条路径从 start 到 end，而非直接走 start -> end 这条边。例如存在一个 middle 节点，使得 start -> middle -> end

+ 若存在 2 的情况，则将当前边 start -> end 从 DAG 中删掉

通过以上描述，我们可以看出思路虽然简单，但是寻找两个节点之间是否存在一条至少含有 1 个节点的路径还是有难度的。若单纯采用暴力来求解，时间复杂度会比较高（O(E*(V+E))），即每个节点开始遍历一遍来判断路径是否存在。这里不难看出，针对同样的路径，我们可能会遍历很多次。

那么考虑是否有方案尽可能少地遍历呢？

对 “尽可能地少遍历” 这个目标，一个可能的方案是引入缓存，空间换时间。遍历时记录节点的可达关系，在后续节点计算时，判断与已有缓存是否有关系，若有关系，则根据缓存运算无需重新计算一次，若无关，则重新计算。该方案操作较为复杂，且容易出错，暂不考虑。

我们再回看一下这个方案，```遍历图中的每一条边```，这导致每次只有 start 和 end 节点这两个信息，需要通过二次遍历来判断其间接依赖关系。为了减少这些二次遍历，可考虑先对图做拓扑排序，然后基于拓扑排序和图中实际存在的边来做边的遍历，这样最大限度保留了边的依赖关系。此时，（方案二）可以修改为如下方式：

+ 获取拓扑排序列表

+ 创建新 DAG 用于存储结果

+ 针对拓扑排序中的每两个节点之间的边，判断原 DAG 中是否存在

+ 若存在则进一步判断两点之间是否存在其他路径，若不存在，则添加到新 DAG 中

+ 新 DAG 即为所求

在方案二中，看起来并没有减少多少工作量，甚至还多计算了一次拓扑排序。其实我们可以优化判断两点之间是否存在其他路径这一流程，借助拓扑排序（顺序：入度为 0 的点到出度为 0 的点）和标记位来简化操作，无需从某个节点开始二次遍历。
在遍历某个节点 i（[1, n-1]）的其他关联 j（[0, i - 1]）节点的过程中，为 j 节点设置标记位，表示是否存在一条从 j 到 i 的路径，若存在则置为 True，不存在则置为 False。这样可以利用前面缓存的思路，遍历到边 [j, i] 时，若标记为 True，即存在一条从 j 到 i 的路径，则可将所有 [x, j] 边的 x 都置为 True，因为 j 到 i 可达，x 到 j 可达，那么 x 到 i 也可达。
基于这个思路，每次在某个节点首次标记为 True 的时候，即为首次判断该边在原 DAG 中存在时，将该边添加到新 DAG 中。该首次标记的过程，即为直接依赖产生的过程，后续再出现标记时，则为通过其他点的非直接依赖，而这些也不必保留。由此，可得到最终方案（方案三）的大致流程如下。

+ 获取拓扑排序序列

+ 针对拓扑排序中的每两个节点之间的边，i 从 [1, n-1]，j 从 [i - 1, 0]，判断原 DAG 中是否存在

+ 若存在，则判断标记位是否为 False，若是则将当前边添加到新 DAG 中，并将标记位置为 True

+ 判断标记位是否为 True，若是则标记以 j 为结束节点的相关节点为 True，直至结束

下面以一个具体例子讲解一下算法流程：

<div  align="center">    
    <img src="../../../imgs/tr_g3.png" width = "660" height = "350" alt="examples" align=center />
</div>

初次迭代时，i 从排序列表的第二个节点开始，j 从第一个节点开始，由于 A->B 在图中，且 A 的标记位为 False，将 A->B 添加到新 DAG 中，并将 A 的标记位置为 True。由于 A 的标记位为 True，因此根据边的关系将以 A 为终点的其他节点（无）标记位置为 True。

二次迭代时，重置前 i - 1 个标记位，i 走到 D 节点，j 先走到 B 节点，此时由于 B->D 不在图中，因此无需修改标记位。由于 B 的标记位为 False，因此不会进入修改关联节点的步骤。j 继而走到 A 节点，由于 A->D 在图中，且 A 的标记位 False，因此需将 A->D 添加到新 DAG 中，并将 A 的标记位置为 True，同时将以 A 为终点的其他节点（无）标记为 True。

三次迭代时，重置前 i - 1 个标记位，i 走到 C 节点，j 先走到 D 节点，此时由于 D->C 在图中且 D 标记位为 False，因此将其添加到新 DAG 中，修改 D 的标记位为 True，修改 D 关联的其他节点（A）标记为 True。j 走到 B 节点，此时由于 B->C 在图中且 B 标记位为 False，因此将其添加到 DAG 中，修改 B 的标记位为 True，同时将以 B 为终点的其他节点（A）标记为 True。

四次迭代就不再赘述了，原理和前三次相同。

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

### 3.2 拓扑排序法
```python
import networkx as nx


def get_topological_sort_list(graph_edge_list):
    g = nx.DiGraph(graph_edge_list)
    return nx.topological_sort(g)


def transitive_reduction(graph):
    new_graph_edge_list = {}
    graph_edge_list = []
    for key, val in graph.items():
        graph_edge_list.extend((key, x) for x in val)

    topo_list = list(get_topological_sort_list(graph_edge_list))
    index_of_topo = {x: index for index, x in enumerate(topo_list)}

    exist_flag = [False for x in graph]
    for i in range(1, len(topo_list)):
        for j in range(i - 1):
            exist_flag[j] = False

        for j in range(i - 1, -1, -1):
            if (topo_list[j], topo_list[i]) in graph_edge_list:
                if not exist_flag[j]:
                    if topo_list[j] not in new_graph_edge_list:
                        new_graph_edge_list[topo_list[j]] = set()
                    new_graph_edge_list[topo_list[j]].add(topo_list[i])

                exist_flag[j] = True

            if exist_flag[j]:
                for start, end in graph_edge_list:
                    if end == topo_list[j]:
                        exist_flag[index_of_topo[start]] = True

    return new_graph_edge_list


if __name__ == '__main__':
    graph = {
        "A": {"B", "C", "D"}, "B": {"C"}, "C": {"E"}, "D": {"C", "E"}, "E": {}
    }
    print(transitive_reduction(graph))
```


## 4. 三方库中的实现


## 参考链接
[[1] wiki](https://en.wikipedia.org/wiki/Transitive_reduction)
[[2] 拓扑排序法实现 —— Github](https://github.com/jafingerhut/cljol/blob/b560fcf44523112d8a671fa7f5ed4a1d5d492784/doc/transitive-reduction-notes.md)
[[3] A. V. Aho, M. R. Garey, and J. D. Ullman, "The transitive reduction of a directed graph", SIAM J. Computing, Vol. 1, No. 2, June 1972](https://doi.org/10.1137/0201008)