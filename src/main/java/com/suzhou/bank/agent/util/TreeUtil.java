package com.suzhou.bank.agent.util;


import com.alibaba.fastjson.JSONArray;
import com.alibaba.fastjson.JSONObject;
import com.suzhou.bank.agent.model.common.BaseTree;
import org.springframework.util.StringUtils;

import java.util.ArrayList;
import java.util.List;
import java.util.Objects;
import java.util.function.BiConsumer;
import java.util.function.Consumer;
import java.util.function.Function;
import java.util.function.Predicate;

/**
 * 树结构工具类
 *
 * @author: csxi
 * @date: 下午2:28 2021/5/6
 */
public class TreeUtil {

    public static <T extends BaseTree> List<T> buildTree(List<T> list, Function<T, String> key, Function<T, String> parent) {
        List<T> tree = new ArrayList<>();
        if (list != null) {
            for (T item : list) {
                String parentKey = parent.apply(item);
                T parentNode = StringUtils.hasText(parentKey) ? find(list, i -> parentKey.equals(key.apply(i))) : null;
                if (parentNode == null) {
                    // 不存在父节点，作为一级节点
                    tree.add(item);
                } else {
                    // 添加进父节点
                    List<T> children = parentNode.getChildren();
                    if (children == null) children = new ArrayList<>();
                    children.add(item);
                    parentNode.setChildren(children);
                }
            }
        }

        return tree;
    }

    public static <T extends BaseTree> List<T> buildTreeTwo(List<T> list, Function<T, Integer> key, Function<T, Integer> parent) {
        List<T> tree = new ArrayList<>();
        if (list != null) {
            for (T item : list) {
                String parentKey = parent.apply(item) == null ? null : String.valueOf(parent.apply(item));
                T parentNode = StringUtils.hasText(parentKey) ? find(list, i -> parentKey.equals(String.valueOf(key.apply(i)))) : null;
                if (parentNode == null) {
                    // 不存在父节点，作为一级节点
                    tree.add(item);
                } else {
                    // 添加进父节点
                    List<T> children = parentNode.getChildren();
                    if (children == null) children = new ArrayList<>();
                    children.add(item);
                    parentNode.setChildren(children);
                }
            }
        }

        return tree;
    }

    public static <T> T find(List<T> list, Predicate<T> predicate) {
        for (T item : list) {
            boolean test = predicate.test(item);
            if (test) return item;
        }
        return null;
    }

    /**
     * 在树结构中查询
     *
     * @param list
     * @param predicate
     * @param <T>
     * @return
     */
    public static <T extends BaseTree> T findInTree(List<T> list, Predicate<T> predicate) {
        if (list != null) {
            for (T t : list) {
                boolean flag = predicate.test(t);
                if (flag) return t;
                T r = (T) findInTree(t.getChildren(), predicate);
                if (r != null) return r;
            }
        }

        return null;
    }

    /**
     * 前序遍历树图并执行
     *
     * @param catalogTree
     * @param <T>
     * @return
     */
    public static <T extends BaseTree, V> List<V> traverse(List<T> catalogTree, Function<T, V> function) {
        List<V> list = new ArrayList<>();
        if (catalogTree != null) {
            for (T t : catalogTree) {
                list.add(function.apply(t));
                list.addAll(traverse(t.getChildren(), function));
            }
        }

        return list;
    }

    public static <T extends BaseTree> void traverse(List<T> catalogTree, Consumer<T> consumer) {
        if (catalogTree != null) {
            for (T t : catalogTree) {
                consumer.accept(t);
                traverse(t.getChildren(), consumer);
            }
        }
    }

    public static <T extends BaseTree> void traverse(T catalogTree, Consumer<T> consumer) {
        if (catalogTree != null) {
            consumer.accept(catalogTree);
            traverse(catalogTree.getChildren(), consumer);
        }
    }

    /**
     * 遍历时可访问到父节点
     *
     * @param list
     * @param consumer
     * @param <T>
     */
    public static <T extends BaseTree> void traverse(List<T> list, BiConsumer<T, T> consumer) {
        _traverse(list, consumer, null);
    }

    private static <T extends BaseTree> void _traverse(List<T> list, BiConsumer<T, T> consumer, T parent) {
        if (list != null) {
            for (T t : list) {
                consumer.accept(t, parent);
                List<T> children = t.getChildren();
                _traverse(children, consumer, t);
            }
        }
    }

    /**
     * 查找list中缺少的父节点编号
     *
     * @param list
     * @param <T>
     * @return
     */
    public static <T extends BaseTree> List<String> findLoseParentNos(List<T> list, Function<T, String> key, Function<T, String> parent) {
        if (list == null) return null;
        List<String> rets = new ArrayList<>();
        for (T t : list) {
            String parentKey = parent.apply(t);
            if (StringUtils.hasText(parentKey)) {
                // 查询父编号是否在目前的list中, 若不在则添加进返回链表
                T t1 = find(list, i -> parentKey.equals(key.apply(i)));
                if (t1 == null) {
                    rets.add(parentKey);
                }
            }
        }
        return rets;
    }

    public static boolean JsonCheck(JSONArray jsonArray) {
        boolean allValuesAreEmpty = true;
        for (int i = 0; i < jsonArray.size(); i++) {
            JSONObject jsonObject = jsonArray.getJSONObject(i);
            for (String key : jsonObject.keySet()) {
                if ("id".equals(key)) {
                    continue;
                }
                Object object = jsonObject.get(key);
                if (Objects.nonNull(object) && !StringUtils.isEmpty(String.valueOf(object))) {
                    allValuesAreEmpty = false;
                    break;
                }
            }
            if (!allValuesAreEmpty) {
                break;
            }
        }
        return allValuesAreEmpty;
    }

    public static boolean checkAllValuesEmpty(JSONObject jsonObject) {
        boolean allEmpty = true;
        for (String key : jsonObject.keySet()) {
            Object value = jsonObject.get(key);
            if (value != null && !StringUtils.isEmpty(String.valueOf(value))) {
                allEmpty = false;
                break;
            }
        }
        return !allEmpty;
    }
}
