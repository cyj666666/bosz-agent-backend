import React, { useState, useRef, useEffect, useCallback } from 'react'
import {
  Layout,
  Checkbox,
  Collapse,
  Button,
  Statistic,
  Table,
  Tag,
  Space,
  Input,
  Spin,
  Card
} from 'antd'
import {
  DownloadOutlined,
  SearchOutlined,
  FilterOutlined,
  LeftOutlined,
  RightOutlined,
  FullscreenOutlined,
  FullscreenExitOutlined,
  CloseOutlined
} from '@ant-design/icons'
import type { TableProps } from 'antd/es/table'
import { useReportApi, type RiskListItem } from '@/hooks/useReportApi'

const { Sider, Content } = Layout
const { Panel } = Collapse

interface MenuItem {
  title: string
  key: string
  children?: { title: string; key: string }[]
}

const ReportPage: React.FC = () => {
  const reportId = 'rep_001'
  const { loading, reportData, riskList } = useReportApi(reportId)

  const [onlySourceModule, setOnlySourceModule] = useState(false)
  const [activeSectionKey, setActiveSectionKey] = useState<string>('1')
  const [openPanels, setOpenPanels] = useState<string[]>(['1', '2', '3'])
  const [highlightRiskKey, setHighlightRiskKey] = useState<string | null>(null)
  // 全屏状态
  const [isFullScreen, setIsFullScreen] = useState(false)
  const [showRiskPanel, setShowRiskPanel] = useState(false)

  const sectionRefMap = useRef<Record<string, HTMLDivElement | null>>({})
  const contentScrollRef = useRef<HTMLDivElement | null>(null)
  const observerRef = useRef<IntersectionObserver | null>(null)
  const highlightTimerRef = useRef<ReturnType<typeof setTimeout> | null>(null)

  // 目录点击：展开面板 + 滚动定位
  const handleMenuClick = (key: string) => {
    if (!openPanels.includes(key)) {
      setOpenPanels(prev => [...prev, key])
    }
    const dom = sectionRefMap.current[key]
    if (dom) {
      dom.scrollIntoView({ behavior: 'smooth', block: 'start' })
      setActiveSectionKey(key)
    }
  }

  // 风险行点击：自动展开面板 + 滚动 + 10s高亮
  const handleRiskRowClick = (record: RiskListItem) => {
    if (!record.relateSectionKey) return
    const targetKey = record.relateSectionKey

    if (!openPanels.includes(targetKey)) {
      setOpenPanels(prev => [...prev, targetKey])
    }

    if (highlightTimerRef.current) {
      clearTimeout(highlightTimerRef.current)
    }
    setHighlightRiskKey(record.key)

    setTimeout(() => {
      const dom = sectionRefMap.current[targetKey]
      if (dom) {
        dom.scrollIntoView({ behavior: 'smooth', block: 'start' })
        setActiveSectionKey(targetKey)
      }
    }, 120)

    highlightTimerRef.current = setTimeout(() => {
      setHighlightRiskKey(null)
    }, 10000)
  }

  // 滚动监听：自动高亮当前章节
  const initObserver = useCallback(() => {
    if (observerRef.current) observerRef.current.disconnect()

    observerRef.current = new IntersectionObserver(
      (entries) => {
        for (const entry of entries) {
          if (entry.isIntersecting) {
            const key = entry.target.getAttribute('data-section-key')
            if (key) setActiveSectionKey(key)
          }
        }
      },
      {
        root: contentScrollRef.current,
        threshold: 0.2
      }
    )

    Object.entries(sectionRefMap.current).forEach(([key, el]) => {
      if (el) {
        el.setAttribute('data-section-key', key)
        observerRef.current!.observe(el)
      }
    })
  }, [])

  useEffect(() => {
    if (!loading) {
      const timer = setTimeout(() => initObserver(), 100)
      return () => {
        clearTimeout(timer)
        observerRef.current?.disconnect()
        if (highlightTimerRef.current) clearTimeout(highlightTimerRef.current)
      }
    }
  }, [loading, initObserver])

  const menuList: MenuItem[] = [
    { title: '一、总体概览', key: '1' },
    {
      title: '二、客户基本情况',
      key: '2',
      children: [
        { title: '2.1 客户概况', key: '2-1' },
        { title: '2.2 股东及实控人', key: '2-2' },
        { title: '2.3 经营范围与资质', key: '2-3' },
        { title: '2.4 财务概况', key: '2-4' }
      ]
    },
    {
      title: '三、业务基本情况',
      key: '3',
      children: [
        { title: '3.1 信贷情况', key: '3-1' },
        { title: '3.2 业务产品情况', key: '3-2' }
      ]
    },
    { title: '四、本次日常定期检查开展情况', key: '4' },
    { title: '五、财务指标变化和潜在风险', key: '5' },
    { title: '六、征信情况和潜在风险', key: '6' },
    { title: '七、资金用途异常', key: '7' },
    { title: '八、潜在合规风险关注点', key: '8' },
    { title: '九、结算情况和潜在风险', key: '9' },
    { title: '十、地方征信和潜在风险', key: '10' }
  ]

  const getStatusTag = (status: string) => {
    const map: Record<string, { color: string; label: string }> = {
      采纳: { color: '#52c41a', label: '采纳' },
      无效: { color: '#8c8c8c', label: '无效' },
      待处理: { color: '#fa8c16', label: '待处理' }
    }
    const item = map[status]
    return <Tag color={item.color}>{item.label}</Tag>
  }

  const riskColumns: TableProps<RiskListItem>['columns'] = [
    {
      title: '状态',
      dataIndex: 'status',
      key: 'status',
      width: 80,
      render: (val) => getStatusTag(val)
    },
    { title: '规则名称', dataIndex: 'ruleName', key: 'ruleName' },
    { title: '风险说明', dataIndex: 'riskDesc', key: 'riskDesc' }
  ]

  if (loading) {
    return (
      <div style={{ height: '100vh', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
        <Spin size="large" tip="报告加载中..." />
      </div>
    )
  }

  return (
    <>
      <style>{`
.hide-scrollbar::-webkit-scrollbar {
  display: none;
}
      `}</style>
      <Layout style={{ minHeight: '100vh', background: '#f7f9fc' }}>
        {/* 左侧目录 */}
        <Sider width={220} style={{ background: '#fff', padding: 16 }} theme="light">
          <div style={{ marginBottom: 16 }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
              <h3 style={{ margin: 0, fontSize: 16, fontWeight: 600 }}>报告目录</h3>
              <Button type="text" size="small" icon={<LeftOutlined />} />
            </div>
            <Checkbox
              checked={onlySourceModule}
              onChange={(e) => setOnlySourceModule(e.target.checked)}
              style={{ marginTop: 8 }}
            >
              只有有溯源模块
            </Checkbox>
          </div>

          <div className="menu-list">
            {menuList.map((m) => (
              <div key={m.key} style={{ marginBottom: 4 }}>
                <div
                  onClick={() => handleMenuClick(m.key)}
                  style={{
                    padding: '6px 8px',
                    borderRadius: 6,
                    background: activeSectionKey === m.key ? '#e8f3ff' : 'transparent',
                    cursor: 'pointer',
                    display: 'flex',
                    justifyContent: 'space-between'
                  }}
                >
                  <span>{m.title}</span>
                  <RightOutlined style={{ fontSize: 12 }} />
                </div>
                {m.children?.map((child) => (
                  <div
                    key={child.key}
                    onClick={() => handleMenuClick(child.key)}
                    style={{
                      padding: '4px 16px',
                      fontSize: 13,
                      cursor: 'pointer',
                      color: activeSectionKey === child.key ? '#1677ff' : '#444',
                      background: activeSectionKey === child.key ? '#f0f7ff' : 'transparent',
                      borderRadius: 4,
                      marginRight: 4
                    }}
                  >
                    {child.title}
                  </div>
                ))}
              </div>
            ))}
          </div>

          <div style={{ position: 'absolute', bottom: 20, left: 16, right: 16 }}>
            <div style={{ fontSize: 12, color: '#666' }}>已完成 10/10 章节</div>
            <div style={{ height: 6, background: '#e5e7eb', borderRadius: 4, marginTop: 6 }}>
              <div style={{ width: '100%', height: '100%', background: '#1677ff', borderRadius: 4 }} />
            </div>
            <div style={{ textAlign: 'right', fontSize: 12, marginTop: 4 }}>100%</div>
          </div>
        </Sider>

        {/* 中间报告内容区域 */}
        <Content style={{ padding: 20, overflow: 'hidden' }}>
          <div
            ref={contentScrollRef}
            style={{ height: 'calc(100vh - 40px)', overflow: 'auto' }}
          >
            {/* 头部标题栏 */}
            <div style={{ background: '#fff', padding: '16px 24px', borderRadius: 12, marginBottom: 16 }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
                <div>
                  <h1 style={{ fontSize: 24, margin: 0 }}>{reportData?.companyName}</h1>
                  <p style={{ color: '#666', margin: '4px 0 0' }}>{reportData?.reportTitle}</p>
                </div>
                <Space>
                  <Button>检查重点</Button>
                  <Button type="primary" onClick={() => setShowRiskPanel(true)}>AI风险识别</Button>
                  <Button>AI分析全文</Button>
                  <Button icon={<DownloadOutlined />}>下载 Word</Button>
                  {/* <Button
                    icon={isFullScreen ? <FullscreenExitOutlined /> : <FullscreenOutlined />}
                    onClick={() => setIsFullScreen(!isFullScreen)}
                  /> */}
                </Space>
              </div>
            </div>

            <Collapse
              activeKey={openPanels}
              onChange={(keys) => setOpenPanels(keys as string[])}
              defaultActiveKey={['1', '2', '3']}
              ghost
              expandIconPosition="end"
            >
              <Panel
                header={
                  <span style={{ fontSize: 16, fontWeight: 600 }}>一、总体概览</span>
                }
                key="1"
                style={{ background: '#ffffff', borderRadius: 12, marginBottom: 12 }}
              >
                <div ref={(el) => { sectionRefMap.current['1'] = el; }}>
                  <Card
                    bordered
                    style={{ background: '#f7f9fc', borderRadius: 8 }}
                  >
                    <p style={{ lineHeight: 1.7, margin: 0 }}>
                      {reportData?.overviewText}
                    </p>
                  </Card>
                </div>
              </Panel>

              <Panel
                header={
                  <span style={{ fontSize: 16, fontWeight: 600 }}>二、客户基本情况</span>
                }
                key="2"
                style={{ background: '#ffffff', borderRadius: 12, marginBottom: 12 }}
              >
                <div ref={(el) => { sectionRefMap.current['2'] = el; }}>
                  <Card
                    bordered
                    // style={
                    //   highlightRiskKey === '1'
                    //     ? {
                    //         borderLeft: '4px solid #fa8c16',
                    //         background: '#fff7e6',
                    //         borderRadius: 8,
                    //       }
                    //     : { borderLeft: '4px solid #4080ff', background: '#f0f6ff', borderRadius: 8 }
                    // }
                    style={{ background: '#f7f9fc', borderRadius: 8 }}
                  >
                    {/* AI风险标签单独一行 */}
                    <div style={{ marginBottom:12 }}>
                      <Tag color="#1677ff">AI风险</Tag>
                    </div>

                    {/* 风险提示文本 */}
                    <p style={{ margin: '0 0 12px 0', lineHeight:1.7 }}>
                      风险提示：工商受益人和系统实控人不一致，最近一次投信后（2026年6月30日），工商登记受益所有人为张伟（持股67%），而系统内实际控制人记录为贾平，两者不一致。
                    </p>

                    {/* 文本域输入框 */}
                    <Input.TextArea
                      rows={4}
                      placeholder="请输入处置意见/备注"
                      style={{ marginBottom:16 }}
                    />

                    {/* 按钮行 */}
                    <div style={{ display: 'flex', justifyContent: 'flex-end', gap:12 }}>
                      <Button>取消</Button>
                      <Button type="primary">保存</Button>
                    </div>
                  </Card>
                  <div style={{ marginTop: 12 }}>
                      <Button>查看溯源消息</Button>
                    </div>
                </div>
              </Panel>


              <Panel
                header={
                  <span style={{ fontSize: 16, fontWeight: 600 }}>三、业务基本情况</span>
                }
                key="3"
                style={{ background: '#ffffff', borderRadius: 12 }}
              >
                <div ref={(el) => { sectionRefMap.current['3'] = el; }}>
                  <Card bordered style={{ background: '#f7f9fc', borderRadius: 8 }}>
                    <div>
                      <h4>（一）信贷情况</h4>
                      <p style={{ lineHeight: 1.7 }}>
                        借款人目前在我行授信总额合计8,000万元，总余额为5,650万元，敞口金额为8,000万元，敞口余额为5,150万元。借款人属于江阴市xx精密集团，集团授信总额为8,000万元，集团总余额为5,650万元。
                      </p>
                      <p style={{ lineHeight: 1.7 }}>
                        借款人办理的业务产品如下：短期流动资金贷款信用余额合计4,000万元（征信贷2,000万元、信保贷2,000万元）；银行承兑汇票用信金额合计1,650万元（一般产品额度1,650万元）。当前借据还款方式变更1笔（余额159万元）、展期2笔（余额78万元）、重组1笔（余额65万元）、借新还旧1笔（余额600万元）。
                      </p>
                    </div>
                  </Card>
                </div>
              </Panel>
              {/* 后续4‑10章节复制上面Panel模板，header内套 <span style={{ fontSize:16,fontWeight:600}}>标题</span> */}
            </Collapse>
          </div>
        </Content>

        {/* 右侧平铺AI风险面板 */}
        {showRiskPanel && (
          <Sider
            width={420}
            theme="light"
            style={{ background: '#fff', padding: 16 }}
          >
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 16 }}>
              <h2 style={{ margin: 0, fontSize: 18, fontWeight: 600 }}>AI风险识别</h2>
              <Space size={4}>
                <Button
                  type="text"
                  icon={isFullScreen ? <FullscreenExitOutlined /> : <FullscreenOutlined />}
                  onClick={() => setIsFullScreen(!isFullScreen)}
                />
                <Button type="text" icon={<CloseOutlined />} onClick={() => setShowRiskPanel(false)} />
              </Space>
            </div>

            <h4 style={{ marginBottom: 12, fontSize: 14, color: '#444' }}>风险识别统计（本报告）</h4>
            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr 1fr', gap: 8, marginBottom: 16 }}>
              <Statistic value={23} title="总数" valueStyle={{ color: '#1677ff', fontSize: 20 }} />
              <Statistic value={9} title="已采纳" valueStyle={{ color: '#52c41a', fontSize: 20 }} />
              <Statistic value={6} title="无效" valueStyle={{ color: '#8c8c8c', fontSize: 20 }} />
              <Statistic value={8} title="待处理" valueStyle={{ color: '#fa8c16', fontSize: 20 }} />
            </div>

            <div style={{ display: 'flex', gap: 8, marginBottom: 12 }}>
              <Input placeholder="搜索规则名称或风险说明" prefix={<SearchOutlined />} />
              <Button icon={<FilterOutlined />} />
            </div>

            {/* 外层div实现隐藏滚动条 */}
            <div
              className="hide-scrollbar"
              style={{
                height: 580,
                overflowY: 'auto',
                msOverflowStyle: 'none',
                scrollbarWidth: 'none'
              }}
            >
              <Table
                size="small"
                columns={riskColumns}
                dataSource={riskList}
                pagination={{ pageSize: 20, total: riskList.length }}
                scroll={{ y: '100%' }}
                onRow={(record) => {
                  return {
                    onClick: () => handleRiskRowClick(record),
                    style: { cursor: 'pointer' }
                  }
                }}
              />
            </div>
          </Sider>
        )}
      </Layout>
    </>
  )
}

export default ReportPage
