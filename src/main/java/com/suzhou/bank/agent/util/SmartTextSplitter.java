package com.suzhou.bank.agent.util;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * 智能字符串拆分工具
 * 按标题→段落→句子的优先级拆分，并让每个块长度尽量接近最大长度
 */
public class SmartTextSplitter {

    private final int maxLength;
    private final boolean trimSpaces;
    private final double targetFillRatio; // 目标填充率 (0.7-0.9)

    // 正则表达式
    private static final Pattern TITLE_PATTERN = Pattern.compile("^(#{1,6}|第[一二三四五六七八九十]+章|[一二三四五六七八九十]+、|\\d+[.、]\\s*).+$", Pattern.MULTILINE);
    private static final Pattern PARAGRAPH_PATTERN = Pattern.compile("\n\\s*\n");
    private static final Pattern SENTENCE_PATTERN = Pattern.compile("[^!?。！？]+[!?。！？]+|[^!?。！？]+$");

    /**
     * 构建器
     */
    public static class Builder {
        private int defaultMaxLength = 1000;
        private boolean trimSpaces = true;
        private double defaultTargetFillRatio = 0.8; // 默认目标填充80%

        public Builder maxLength(int maxLength) {
            if (maxLength <= 0) throw new IllegalArgumentException("maxLength必须大于0");
            this.defaultMaxLength = maxLength;
            return this;
        }

        public Builder trimSpaces(boolean trimSpaces) {
            this.trimSpaces = trimSpaces;
            return this;
        }

        public Builder targetFillRatio(double ratio) {
            if (ratio <= 0.1 || ratio > 1.0) throw new IllegalArgumentException("targetFillRatio必须在0.1-1.0之间");
            this.defaultTargetFillRatio = ratio;
            return this;
        }

        public SmartTextSplitter build() {
            return new SmartTextSplitter(this);
        }
    }

    private SmartTextSplitter(Builder builder) {
        this.maxLength = builder.defaultMaxLength;
        this.trimSpaces = builder.trimSpaces;
        this.targetFillRatio = Math.min(0.95, Math.max(0.6, builder.defaultTargetFillRatio));
    }

    /**
     * 主拆分方法
     */
    public List<String> split(String text) {
        List<String> result = new ArrayList<>();
        if (text == null || text.trim().isEmpty()) return result;

        // 1. 先按标题拆分
        List<String> titleChunks = splitByTitles(text);

        for (String titleChunk : titleChunks) {
            processChunkAtLevel(titleChunk, result, SplitLevel.TITLE);
        }

        return result;
    }

    /**
     * 按指定级别处理文本块
     */
    private void processChunkAtLevel(String chunk, List<String> result, SplitLevel currentLevel) {
        // 如果当前块已经符合长度要求
        if (chunk.length() <= maxLength) {
            addOptimizedChunk(chunk, result);
            return;
        }

        // 根据当前级别决定下一步拆分方式
        SplitLevel nextLevel = getNextLevel(currentLevel);

        if (nextLevel == null) {
            // 已经是最后级别（句子级别），按字符智能拆分
            List<String> charChunks = splitByCharactersSmart(chunk);
            for (String charChunk : charChunks) {
                addToResult(result, charChunk);
            }
            return;
        }

        // 按下一级别拆分单元
        List<String> units = splitByLevel(chunk, nextLevel);

        // 智能合并单元，使每个块接近最大长度
        List<String> mergedChunks = mergeUnitsSmartly(units, nextLevel);

        // 处理合并后的块
        for (String mergedChunk : mergedChunks) {
            if (mergedChunk.length() <= maxLength) {
                addOptimizedChunk(mergedChunk, result);
            } else {
                // 递归处理仍然过长的块
                processChunkAtLevel(mergedChunk, result, nextLevel);
            }
        }
    }

    /**
     * 智能合并单元，使每个块接近目标长度
     */
    private List<String> mergeUnitsSmartly(List<String> units, SplitLevel level) {
        List<String> mergedChunks = new ArrayList<>();
        StringBuffer currentChunk = new StringBuffer();

        int targetSize = (int) (maxLength * targetFillRatio);
        int minAcceptableSize = (int) (maxLength * 0.5); // 最小可接受大小

        for (String unit : units) {
            // 如果单元本身超过最大长度，单独处理
            if (unit.length() > maxLength) {
                if (currentChunk.length() > 0) {
                    mergedChunks.add(currentChunk.toString());
                    currentChunk.setLength(0);
                }
                mergedChunks.add(unit);
                continue;
            }

            // 计算添加后的长度（考虑分隔符）
            int separatorLength = (currentChunk.length() > 0 && level != SplitLevel.SENTENCE) ?
                    (level == SplitLevel.TITLE ? 2 : 1) : 0;
            int potentialLength = currentChunk.length() + separatorLength + unit.length();

            // 决定是否加入当前块
            if (currentChunk.length() == 0) {
                currentChunk.append(unit);
            } else if (potentialLength <= maxLength) {
                // 可以加入当前块
                if (separatorLength > 0) {
                    if (level == SplitLevel.TITLE) {
                        currentChunk.append("\n\n");
                    } else {
                        currentChunk.append("\n");
                    }
                }
                currentChunk.append(unit);

                // 如果当前块已经达到或超过目标大小，考虑结束
                if (currentChunk.length() >= targetSize) {
                    mergedChunks.add(currentChunk.toString());
                    currentChunk.setLength(0);
                }
            } else {
                // 不能加入当前块
                // 检查当前块是否太小
                if (currentChunk.length() < minAcceptableSize) {
                    // 尝试让当前块稍微超过maxLength，但要保持语义
                    if (potentialLength <= maxLength * 1.1) {
                        if (separatorLength > 0) {
                            if (level == SplitLevel.TITLE) {
                                currentChunk.append("\n\n");
                            } else {
                                currentChunk.append("\n");
                            }
                        }
                        currentChunk.append(unit);
                        mergedChunks.add(currentChunk.toString());
                        currentChunk.setLength(0);
                    } else {
                        // 不能加入，保存当前块
                        mergedChunks.add(currentChunk.toString());
                        currentChunk.setLength(0);
                        currentChunk.append(unit);
                    }
                } else {
                    // 当前块大小合适，保存它
                    mergedChunks.add(currentChunk.toString());
                    currentChunk.setLength(0);
                    currentChunk.append(unit);
                }
            }
        }

        // 处理最后一个块
        if (currentChunk.length() > 0) {
            mergedChunks.add(currentChunk.toString());
        }

        return mergedChunks;
    }

    /**
     * 按级别拆分
     */
    private List<String> splitByLevel(String text, SplitLevel level) {
        switch (level) {
            case TITLE:
                return splitByTitles(text);
            case PARAGRAPH:
                return splitByParagraphs(text);
            case SENTENCE:
                return splitBySentences(text);
            default:
                return new ArrayList<>();
        }
    }

    /**
     * 智能按字符拆分（均匀分布）
     */
    private List<String> splitByCharactersSmart(String text) {
        List<String> chunks = new ArrayList<>();

        if (text.length() <= maxLength) {
            chunks.add(text);
            return chunks;
        }

        // 计算需要拆分成几块
        int numChunks = (int) Math.ceil((double) text.length() / maxLength);
        int chunkSize = (int) Math.ceil((double) text.length() / numChunks);

        int start = 0;
        while (start < text.length()) {
            int end = Math.min(start + chunkSize, text.length());

            if (end < text.length()) {
                // 寻找最佳分割点
                end = findOptimalSplitPoint(text, start, end);
            }

            chunks.add(text.substring(start, end));
            start = end;
        }

        return chunks;
    }

    /**
     * 寻找最优分割点
     */
    private int findOptimalSplitPoint(String text, int start, int preferredEnd) {
        int textLength = text.length();
        int optimalEnd = preferredEnd;

        // 搜索窗口：从preferredEnd前后各找20%的范围
        int searchStart = Math.max(start, preferredEnd - (int) (maxLength * 0.2));
        int searchEnd = Math.min(textLength, preferredEnd + (int) (maxLength * 0.2));

        List<SplitPoint> candidates = new ArrayList<>();

        // 收集所有可能的分割点
        for (int i = searchStart; i <= searchEnd; i++) {
            if (i <= start || i >= textLength) continue;

            int score = calculateSplitPointScore(text, start, i, preferredEnd);
            if (score > 0) {
                candidates.add(new SplitPoint(i, score));
            }
        }

        // 按分数排序，选择最佳分割点
        if (!candidates.isEmpty()) {
            candidates.sort((a, b) -> b.score - a.score);
            optimalEnd = candidates.get(0).position;
        }

        // 确保不会产生太小的块
        if (optimalEnd - start < maxLength * 0.3 && optimalEnd < textLength - 10) {
            // 尝试找更远的分割点
            for (int i = optimalEnd; i < Math.min(textLength, optimalEnd + 50); i++) {
                if (calculateSplitPointScore(text, start, i, preferredEnd) > 0) {
                    optimalEnd = i;
                    break;
                }
            }
        }

        return optimalEnd;
    }

    /**
     * 计算分割点得分
     */
    private int calculateSplitPointScore(String text, int start, int position, int preferredEnd) {
        if (position <= start || position >= text.length()) return 0;

        int score = 0;

        // 1. 长度接近度（最重要）
        int lengthFromStart = position - start;
        int lengthDiff = Math.abs(lengthFromStart - (int) (maxLength * targetFillRatio));
        score += Math.max(0, 100 - lengthDiff * 2);

        // 2. 语义边界加分
        char prevChar = text.charAt(position - 1);
        char currChar = position < text.length() ? text.charAt(position) : ' ';

        // 段落边界
        if (position > 1 && text.substring(position - 2, position).equals("\n\n")) {
            score += 80;
        }
        // 句子结束标点
        else if (prevChar == '.' || prevChar == '!' || prevChar == '?' ||
                prevChar == '。' || prevChar == '！' || prevChar == '？') {
            score += 60;
        }
        // 逗号、分号
        else if (prevChar == ',' || prevChar == ';' ||
                prevChar == '，' || prevChar == '；') {
            score += 30;
        }
        // 空格
        else if (Character.isWhitespace(prevChar)) {
            score += 10;
        }

        // 3. 位置接近preferredEnd加分
        int posDiff = Math.abs(position - preferredEnd);
        score += Math.max(0, 50 - posDiff);

        // 4. 避免在单词中间分割（检查前后字符）
        if (Character.isLetterOrDigit(prevChar) && Character.isLetterOrDigit(currChar)) {
            score -= 40; // 在单词中间分割减分
        }

        return Math.max(0, score);
    }

    /**
     * 智能添加块到结果（避免过小的块）
     */
    private void addOptimizedChunk(String chunk, List<String> result) {
        if (chunk.length() < maxLength * 0.2 && result.size() > 0) {
            // 如果块太小，尝试合并到上一个块
            String lastChunk = result.get(result.size() - 1);
            if (lastChunk.length() + chunk.length() <= maxLength * 1.1) {
                result.set(result.size() - 1, lastChunk + "\n" + chunk);
                return;
            }
        }
        addToResult(result, chunk);
    }

    /**
     * 分割点辅助类
     */
    private static class SplitPoint {
        final int position;
        final int score;

        SplitPoint(int position, int score) {
            this.position = position;
            this.score = score;
        }
    }

    /**
     * 拆分级别枚举
     */
    private enum SplitLevel {
        TITLE,    // 标题级别
        PARAGRAPH, // 段落级别
        SENTENCE   // 句子级别
    }

    private SplitLevel getNextLevel(SplitLevel current) {
        switch (current) {
            case TITLE:
                return SplitLevel.PARAGRAPH;
            case PARAGRAPH:
                return SplitLevel.SENTENCE;
            default:
                return null;
        }
    }

    /**
     * 按标题拆分
     */
    private List<String> splitByTitles(String text) {
        List<String> result = new ArrayList<>();
        if (text == null || text.isEmpty()) return result;

        List<Integer> titleStarts = new ArrayList<>();
        Matcher matcher = TITLE_PATTERN.matcher(text);

        while (matcher.find()) {
            titleStarts.add(matcher.start());
        }

        if (titleStarts.isEmpty()) {
            result.add(text);
            return result;
        }

        int lastEnd = 0;
        for (int i = 0; i < titleStarts.size(); i++) {
            int start = titleStarts.get(i);

            if (start > lastEnd) {
                String beforeTitle = text.substring(lastEnd, start);
                if (!beforeTitle.trim().isEmpty()) {
                    result.add(beforeTitle);
                }
            }

            int end = (i + 1 < titleStarts.size()) ? titleStarts.get(i + 1) : text.length();
            result.add(text.substring(start, end));
            lastEnd = end;
        }

        if (lastEnd < text.length()) {
            String remaining = text.substring(lastEnd);
            if (!remaining.trim().isEmpty()) {
                result.add(remaining);
            }
        }

        return result;
    }

    /**
     * 按段落拆分
     */
    private List<String> splitByParagraphs(String text) {
        List<String> paragraphs = new ArrayList<>();
        if (text == null || text.isEmpty()) return paragraphs;

        String[] parts = PARAGRAPH_PATTERN.split(text);
        for (String part : parts) {
            String trimmed = part.trim();
            if (!trimmed.isEmpty()) {
                paragraphs.add(trimmed);
            }
        }

        return paragraphs.isEmpty() ? Collections.singletonList(text) : paragraphs;
    }

    /**
     * 按句子拆分
     */
    private List<String> splitBySentences(String text) {
        List<String> sentences = new ArrayList<>();
        if (text == null || text.isEmpty()) return sentences;

        Matcher matcher = SENTENCE_PATTERN.matcher(text);
        while (matcher.find()) {
            String sentence = matcher.group().trim();
            if (!sentence.isEmpty()) {
                sentences.add(sentence);
            }
        }

        return sentences.isEmpty() ? Collections.singletonList(text) : sentences;
    }

    /**
     * 添加到结果列表
     */
    private void addToResult(List<String> result, String chunk) {
        String processed = trimSpaces ? chunk.trim() : chunk;
        if (!processed.isEmpty()) {
            result.add(processed);
        }
    }

    /**
     * 便捷静态方法
     */
    public static List<String> split(String text, int maxLength) {
        return new Builder()
                .maxLength(maxLength)
                .targetFillRatio(0.8)
                .build()
                .split(text);
    }

    /**
     * 测试方法
     */
    public static void main(String[] args) {
        // 创建测试文本
        // String testText = createTestText();

        String testText = "已知信息如下，已知企业所属行业为软件和信息技术服务业，\n" +
                "2024年年报中，\n" +
                "企业的资产负债表相关的重点科目信息如下：\n" +
                "资产总计为4147889.98万元，\n" +
                "资产总计同比变化率为9.64%。\n" +
                "流动资产合计为2406214.20万元，占总资产的58.01%，\n" +
                "流动资产同比变化率为13.50%，\n" +
                "非流动资产合计为1741675.78万元，占总资产的41.99%，\n" +
                "非流动资产同比变化率为4.72%。\n" +
                "\n" +
                "2024年年报中，负债总计为2276402.71万元，同比变化率为13.26%。\n" +
                "流动负债合计为1535904.79万元，\n" +
                "占负债总计比重为67.47%。\n" +
                "流动负债同比变化率为18.99%，\n" +
                "非流动负债合计为740497.91万元，\n" +
                "占负债总计比重为32.53%。\n" +
                "非流动负债同比变化率为2.97%。实收资本当年同比变化率为-0.16%。公司实际收到的股东出资额在减少，可能反映了公司资本结构的变化或股东权益的缩减。应付账款为616202.21万元，占总负债比率为27.07%。\n" +
                "应付账款同比变化率为20.81%。\n" +
                "\n" +
                "长期借款为467298.18万元，占总负债比率为20.53%。\n" +
                "长期借款同比变化率为2.60%。\n" +
                "2024年年报中，资产负债率为54.8800%。\n" +
                "2024年年报中，企业的流动比率为1.5666。\n" +
                "2024年年报中，速动比率为1.2380。\n" +
                "2024年年报中，已获利息倍数为2.1761。\n" +
                "2024年年报中，带息负债比率为41.77%。\n" +
                "2024年年报中，债务与权益比例为121.64%。\n" +
                "2024年年报中，长期债务占资本比率为28.35%。以下内容为企业偿债能力相关的重点财务指标的变动情况，以及与同行业的财务均值对比的情况，其中表现良好的指标如下：资产负债率国资委同行业均值为61.00%，资产负债率小于国资委同行业均值，\n" +
                "在同业内的水平区间为良好水平。企业总资产中负债的比例降低，企业的偿债压力减小，财务结构更加稳健。从流动比率来看，企业具备足够的短期偿债能力。\n" +
                "速动比率国资委同行业均值为110.0000，\n" +
                "在行业内的比较水平为一般，\n" +
                "企业速动比率小于国资委同行业均值，在行业内表现较差，但数值大于1，整体短期偿债能力较好。企业速动资产对流动负债的覆盖能力增强，短期偿债风险降低。债务与权益比例来看，长期债务结构较为健康。长期债务占资本比率来看，财务结构较为稳健。企业长期债务在总资本中的比例较低，企业的长期偿债压力减小，财务稳定性增强。经营性现金流短债覆盖度较好，经营性现金流可以覆盖短期负债。企业经营活动产生的现金流量对短期债务的覆盖能力增强，企业短期偿债的现金流保障更加充足。货币资金短债覆盖度较好，货币资金可以覆盖短期负债。企业持有的货币资金对短期债务的覆盖能力提高，企业短期偿债的流动性风险降低。以下内容为企业偿债能力相关的重点财务指标的变动情况，以及与同行业的财务均值对比的情况，其中表现较差的指标如下：已获利息倍数国资委同行业均值为4.5000，已获利息倍数低于国资委行业均值，\n" +
                "在同业内的水平区间为一般水平。企业偿付债务利息的能力在降低，财务风险增加。带息负债比率国资委同行业均值为37.4000%，带息负债比率高于国资委同行业均值，\n" +
                "在同行业内处于较差水平。财务异常情况：企业在短期内面临较大的偿债压力。\n" +
                "结合以上财务指标情况，可以得出结论：偿债能力下降。你是一位信贷领域财务分析专家，请根据上述已知信息，站在专业的财务分析师视角，帮我分析企业的偿债能力，用户企业尽调调查，要求：\n" +
                "1、重点科目分析：客观分析企业偿债能力相关的财务科目，可以结合科目同比变化情况以及与同行业均值的比较情况。\n" +
                "2、重点指标分析：对偿债能力表现良好、较差的指标区分总结分析；\n" +
                "3、财务异常分析：对表现异常的财务指标进行总结分析；没有异常科目时不分析\n" +
                "4、总结：结合全部的内容，分析能力的好坏，以及能力上升或下降。\n" +
                "\n" +
                "#绝对禁止\n" +
                "绝对禁止上述具体要求出现在回答结果中，回答结果只提供分析的最终结果\n" +
                "绝对禁止出现“根据查询结果”类似的文案\n" +
                "\n" +
                "\n" +
                "数据详情追踪ID:[ 251204143155289216b9a8006400 ]";

        System.out.println("📊 测试智能文本拆分工具");
        System.out.println("原始文本长度: " + testText.length());
        System.out.println("最大拆分长度: " + 500);
        System.out.println("目标填充率: 80%");
        System.out.println(repeatString("=", 60));

        // 创建拆分器
        SmartTextSplitter splitter = new Builder()
                .maxLength(500)
                .targetFillRatio(1)
                .trimSpaces(true)
                .build();

        long startTime = System.currentTimeMillis();
        List<String> chunks = splitter.split(testText);
        long endTime = System.currentTimeMillis();

        System.out.println("拆分结果 (" + chunks.size() + " 个块, 耗时 " + (endTime - startTime) + "ms):");
        System.out.println(repeatString("=", 60));

        // 分析结果
        analyzeResults(chunks, 200);

        // 显示前几个块的内容
        System.out.println("\n📝 前5个块的内容预览:");
        System.out.println(repeatString("-", 60));
        for (int i = 0; i < chunks.size(); i++) {
            System.out.println("\n[块 " + (i + 1) + "] 长度: " + chunks.get(i).length());
            System.out.println(repeatString("-", 40));
            System.out.println(chunks.get(i));
            // System.out.println(chunks.get(i).substring(0, Math.min(80, chunks.get(i).length())) +
            //         (chunks.get(i).length() > 80 ? "..." : ""));
        }
    }

    // 自定义的字符串重复方法
    public static String repeatString(String str, int count) {
        if (count <= 0) return "";
        StringBuffer sb = new StringBuffer();
        for (int i = 0; i < count; i++) {
            sb.append(str);
        }
        return sb.toString();
    }

    private static void analyzeResults(List<String> chunks, int maxLength) {
        if (chunks.isEmpty()) return;

        int totalLength = 0;
        int minLength = Integer.MAX_VALUE;
        int maxLengthFound = 0;
        int optimalCount = 0; // 长度在70%-90%之间的块

        System.out.println("\n📈 长度分布分析:");
        System.out.println(repeatString("-", 40));

        for (int i = 0; i < chunks.size(); i++) {
            String chunk = chunks.get(i);
            int length = chunk.length();
            totalLength += length;
            minLength = Math.min(minLength, length);
            maxLengthFound = Math.max(maxLengthFound, length);

            double ratio = (double) length / maxLength;
            String status;
            if (length > maxLength) {
                status = "❌ 超长";
            } else if (ratio >= 0.7 && ratio <= 0.9) {
                status = "✅ 最优";
                optimalCount++;
            } else if (ratio >= 0.5) {
                status = "⚠️  可接受";
            } else {
                status = "⚠️  偏小";
            }

            System.out.printf("块 %2d: %3d字符 (%.1f%%) %s\n",
                    i + 1, length, ratio * 100, status);
        }

        double avgLength = (double) totalLength / chunks.size();
        double avgRatio = avgLength / maxLength;

        System.out.println("\n📊 统计摘要:");
        System.out.println(repeatString("-", 40));
        System.out.printf("总块数: %d\n", chunks.size());
        System.out.printf("总字符数: %d\n", totalLength);
        System.out.printf("平均长度: %.1f (%.1f%%)\n", avgLength, avgRatio * 100);
        System.out.printf("最小长度: %d (%.1f%%)\n", minLength, (double) minLength / maxLength * 100);
        System.out.printf("最大长度: %d (%.1f%%)\n", maxLengthFound, (double) maxLengthFound / maxLength * 100);
        System.out.printf("最优块比例: %.1f%%\n", (double) optimalCount / chunks.size() * 100);

        // 检查是否有超长的块
        boolean hasOverLength = maxLengthFound > maxLength;
        if (hasOverLength) {
            System.out.println("\n⚠️  警告: 存在超长的块");
        } else {
            System.out.println("\n✅ 所有块长度都在限制范围内");
        }
    }
}