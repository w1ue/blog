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

在该方案中，不难发现，在计算每个节点的非直接依赖节点时，我们可以借助缓存对算法作出优化，比如某个节点 D 同时是 A 和 B 的非直接依赖，若是可以把以 A 为根节点的子树缓存下来，那么在后续的计算中只需计算一次即可，无需每次都从头遍历一遍。

### 2.2 拓扑排序法

该方法是在 stackoverflow 上面一个关于该算法的回答上找到了一个评论，由于无法下载到原始论文[3]，所以把这篇博客[2]看了一遍，大致整理一下思路写在这里。

对于该问题，一种可行的思路（方案一）如下：

+ 遍历 DAG 中的每一条边，start -> end
+ 判断是否存在一条路径从 start 到 end，而非直接走 start -> end 这条边。例如存在一个 middle 节点，满足start -> middle -> end
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

**在上述算法流程中，j 的遍历顺序是否能修改成正序，为什么？**
不能，考虑拓扑排序的特性，逆序意味着从距离 i 节点相对最近或者相对平级的节点开始遍历。这样在修改直接关联节点时，会按照较长的一条依赖关系来改。若按照正序的话，可能会把本来需要删除的边额外添加进去，使得结果不正确。如第 1 节中的 G1 所示，若改为正序，则可以看到算法流程如下所示：

<div  align="center">    
    <img src="../../../imgs/tr_g4.png" width = "660" height = "350" alt="examples" align=center />
</div>

## 3. 算法实现
### 3.1 直接法
```python
def remove_redundant_edge_by_set(graph: Dict[str, set]) -> Dict[str, set]:
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

    remove_edge = set()
    for node, edges in graph.items():
        current_remove_edge = set(edges).intersection(undirect_nodes[node])
        if len(current_remove_edge) > 0:
            remove_edge |= set((node, x) for x in current_remove_edge)

    new_graph = copy.deepcopy(graph)
    for start, end in remove_edge:
        new_graph[start].remove(end)

    return new_graph

```

### 3.2 拓扑排序法
```python
def remove_redundant_edge_by_sort(graph: Dict[str, set]) -> Dict[str, set]:
    visited = {}
    topo_list = []

    def dfs(graph, node):
        dfs[node] = 1
        topo_list.append(node)

        for next in graph[node]:
            if visited[next] == 0:
                dfs(graph, next)

    index_of_topo = {x: index for index, x in enumerate(topo_list)}

    exist_flag = [False for x in graph]
    new_edge_set = set()
    for i in range(1, len(topo_list)):
        if len(graph[topo_list[i]]) == 0:
            continue

        for j in range(i - 1):
            exist_flag[j] = False

        for j in range(i - 1, -1, -1):
            if topo_list[i] in graph[topo_list[j]]:
                if not exist_flag[j]:
                    new_edge_set.add((topo_list[j], topo_list[i]))
                    exist_flag[j] = True

            if exist_flag[j]:
                for start, end in new_edge_set:
                    if end == topo_list[j]:
                        exist_flag[index_of_topo[start]] = True

    new_graph = {}
    for start, end in new_edge_set:
        if start not in new_graph:
            new_graph[start] = set()

        if end not in new_graph:
            new_graph[end] = set()

        new_graph[start].add(end)

    return new_graph

```

其中，首先用 dfs 获取拓扑排序列表，在此尝试过 networkx，发现在首次运行时性能较差，因此简单写了一个获取拓扑排序的步骤，为了可以清晰看到执行步骤就不单独抽取函数了。

## 4. 算法性能

针对上述代码做了一个简单的测试，首先按照一定规则生成一组不同节点个数的图（包含固定个数个冗余边），分别调用两种方法并计算其运行时间，可得到其运行结果如下图所示：

<div  align="center">    
    <img src="../../../imgs/tr_g5.png" width = "400" height = "280" alt="examples" align=center />
</div>

图中横坐标表示节点个数，纵坐标表示运行时间。
从图中可看出，set 方式随着问题规模的增大，呈指数级增长，而 sort 方式则呈线性增长，大致符合 O(V + E) 的规律。


## 5. 三方库中的实现
在 python 的 networkx 这个库中有这个方法，且可以直接调用，以下是源码，我们来简单分析以下整个流程。

```python
def transitive_reduction(G):
    """ Returns transitive reduction of a directed graph

    The transitive reduction of G = (V,E) is a graph G- = (V,E-) such that
    for all v,w in V there is an edge (v,w) in E- if and only if (v,w) is
    in E and there is no path from v to w in G with length greater than 1.

    Parameters
    ----------
    G : NetworkX DiGraph
        A directed acyclic graph (DAG)

    Returns
    -------
    NetworkX DiGraph
        The transitive reduction of `G`

    Raises
    ------
    NetworkXError
        If `G` is not a directed acyclic graph (DAG) transitive reduction is
        not uniquely defined and a :exc:`NetworkXError` exception is raised.

    References
    ----------
    https://en.wikipedia.org/wiki/Transitive_reduction

    """
    if not is_directed_acyclic_graph(G):
        msg = "Directed Acyclic Graph required for transitive_reduction"
        raise nx.NetworkXError(msg)
    TR = nx.DiGraph()
    TR.add_nodes_from(G.nodes())
    descendants = {}
    # count before removing set stored in descendants
    check_count = dict(G.in_degree)
    for u in G:
        u_nbrs = set(G[u])
        for v in G[u]:
            if v in u_nbrs:
                if v not in descendants:
                    descendants[v] = {y for x, y in nx.dfs_edges(G, v)}
                u_nbrs -= descendants[v]
            check_count[v] -= 1
            if check_count[v] == 0:
                del descendants[v]
        TR.add_edges_from((u, v) for v in u_nbrs)
    return TR
```

在上述算法中，首先对传入参数做了校验，接着计算出每个节点的入度，然后遍历每个节点，计算方式和 set 方式类似，依次计算每个 node 节点的所有直接依赖节点和间接依赖节点，并作差集，利用入度来控制不会把依赖节点减至 0。整个算法的核心实现逻辑和 set 方式类似，只是看起来有多余的遍历，set 方式是一次计算，多次使用，而这个算法看起来有很多冗余的计算和遍历，时间耗时也会增加。
下面是添加了该算法之后的测试数据，随着数据规模的增大，该算法的性能也在急剧恶化。

<div  align="center">    
    <img src="../../../imgs/tr_g6.png" width = "400" height = "280" alt="examples" align=center />
</div>

所以呢，如果追求性能，且对数据规模要求比较大的情况下，建议还是选择 sort 方式，如果只是快速实现验证效果，还是建议 networkx 挺好的，用起来简单粗暴，代码也不几行，就是性能差一点。


## 参考链接
[[1] wiki](https://en.wikipedia.org/wiki/Transitive_reduction)
[[2] 拓扑排序法实现 —— Github](https://github.com/jafingerhut/cljol/blob/b560fcf44523112d8a671fa7f5ed4a1d5d492784/doc/transitive-reduction-notes.md)
[[3] A. V. Aho, M. R. Garey, and J. D. Ullman, "The transitive reduction of a directed graph", SIAM J. Computing, Vol. 1, No. 2, June 1972](https://doi.org/10.1137/0201008)