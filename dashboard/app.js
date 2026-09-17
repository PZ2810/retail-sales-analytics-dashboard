/**
 * Interactive Retail Sales Analytics Dashboard Logic
 * Powered by Chart.js & Vanilla JavaScript
 */

document.addEventListener('DOMContentLoaded', () => {
  // Check if data is available
  const rawData = window.SUPERSTORE_DATA || [];
  if (!rawData.length) {
    console.error('Data not loaded! Please check data.js');
    return;
  }

  // State management for filters
  const state = {
    region: 'All',
    segment: 'All',
    year: 'All',
    productTab: 'top' // 'top' or 'bottom'
  };

  // Chart instances container
  let charts = {
    trend: null,
    subcategory: null,
    discount: null,
    region: null,
    segment: null
  };

  // DOM Elements
  const elRegionFilter = document.getElementById('filter-region');
  const elSegmentFilter = document.getElementById('filter-segment');
  const elYearFilter = document.getElementById('filter-year');
  const elResetBtn = document.getElementById('btn-reset');
  const elFilteredCount = document.getElementById('filtered-count');

  // KPI elements
  const elKpiRevenue = document.getElementById('kpi-revenue');
  const elKpiProfit = document.getElementById('kpi-profit');
  const elKpiMargin = document.getElementById('kpi-margin');
  const elKpiOrders = document.getElementById('kpi-orders');
  const elKpiDiscount = document.getElementById('kpi-discount');

  // Table elements
  const elTabTop = document.getElementById('tab-top');
  const elTabBottom = document.getElementById('tab-bottom');
  const elProductTableBody = document.getElementById('product-table-body');

  // Currency & number formatters
  const formatCurrency = (val) => '$' + Math.round(val).toLocaleString();
  const formatCompact = (val) => {
    if (Math.abs(val) >= 1000000) return '$' + (val / 1000000).toFixed(2) + 'M';
    if (Math.abs(val) >= 1000) return '$' + (val / 1000).toFixed(1) + 'K';
    return '$' + Math.round(val);
  };

  // Filter dataset based on current state
  function getFilteredData() {
    return rawData.filter(item => {
      const matchRegion = state.region === 'All' || item.reg === state.region;
      const matchSegment = state.segment === 'All' || item.seg === state.segment;
      const matchYear = state.year === 'All' || item.y.toString() === state.year;
      return matchRegion && matchSegment && matchYear;
    });
  }

  // Update KPI Cards
  function updateKPIs(data) {
    const totalRevenue = data.reduce((sum, d) => sum + d.s, 0);
    const totalProfit = data.reduce((sum, d) => sum + d.p, 0);
    const marginPct = totalRevenue > 0 ? (totalProfit / totalRevenue) * 100 : 0;
    
    // Unique orders
    const orderSet = new Set(data.map(d => d.id));
    const totalOrders = orderSet.size;
    const avgOrderValue = totalOrders > 0 ? totalRevenue / totalOrders : 0;

    // Loss-making transactions
    const lossOrders = data.filter(d => d.p < 0).length;
    const lossPct = data.length > 0 ? (lossOrders / data.length) * 100 : 0;

    // Avg discount
    const avgDiscount = data.length > 0 ? (data.reduce((sum, d) => sum + d.d, 0) / data.length) * 100 : 0;

    // Update text
    elKpiRevenue.textContent = formatCurrency(totalRevenue);
    elKpiProfit.textContent = formatCurrency(totalProfit);
    elKpiMargin.textContent = marginPct.toFixed(2) + '%';
    elKpiOrders.textContent = totalOrders.toLocaleString();
    elKpiDiscount.textContent = avgDiscount.toFixed(1) + '%';

    // Subtext details
    document.getElementById('sub-revenue').textContent = `Avg Order Value: ${formatCurrency(avgOrderValue)}`;
    document.getElementById('sub-profit').textContent = totalProfit >= 0 ? 'Profitable Operations' : 'Net Deficit';
    document.getElementById('sub-margin').textContent = marginPct >= 12 ? 'Healthy Margin' : 'Sub-Optimal Margin';
    document.getElementById('sub-orders').textContent = `${lossPct.toFixed(1)}% unprofitable lines`;
    document.getElementById('sub-discount').textContent = `${data.length.toLocaleString()} total items`;

    elFilteredCount.textContent = `${data.length.toLocaleString()} of 9,994`;
  }

  // Render Charts
  function updateCharts(data) {
    // 1. Monthly Revenue & Profit Trend
    const monthlyMap = {};
    data.forEach(d => {
      if (!monthlyMap[d.ym]) {
        monthlyMap[d.ym] = { sales: 0, profit: 0 };
      }
      monthlyMap[d.ym].sales += d.s;
      monthlyMap[d.ym].profit += d.p;
    });

    const sortedMonths = Object.keys(monthlyMap).sort();
    const trendSales = sortedMonths.map(m => monthlyMap[m].sales);
    const trendProfit = sortedMonths.map(m => monthlyMap[m].profit);

    if (charts.trend) charts.trend.destroy();
    const ctxTrend = document.getElementById('chart-trend').getContext('2d');
    charts.trend = new Chart(ctxTrend, {
      type: 'line',
      data: {
        labels: sortedMonths,
        datasets: [
          {
            label: 'Sales ($)',
            data: trendSales,
            borderColor: '#38bdf8',
            backgroundColor: 'rgba(56, 189, 248, 0.1)',
            fill: true,
            tension: 0.3,
            borderWidth: 2.5,
            pointRadius: sortedMonths.length > 24 ? 0 : 3
          },
          {
            label: 'Profit ($)',
            data: trendProfit,
            borderColor: '#10b981',
            backgroundColor: 'transparent',
            borderDash: [5, 5],
            tension: 0.3,
            borderWidth: 2,
            pointRadius: sortedMonths.length > 24 ? 0 : 3
          }
        ]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        interaction: { mode: 'index', intersect: false },
        plugins: {
          legend: { labels: { color: '#94a3b8', font: { size: 11, family: 'Inter' } } },
          tooltip: {
            callbacks: {
              label: (ctx) => `${ctx.dataset.label}: ${formatCurrency(ctx.parsed.y)}`
            }
          }
        },
        scales: {
          x: {
            grid: { color: 'rgba(255, 255, 255, 0.05)' },
            ticks: { color: '#64748b', maxTicksLimit: 12, font: { size: 10 } }
          },
          y: {
            grid: { color: 'rgba(255, 255, 255, 0.05)' },
            ticks: {
              color: '#64748b',
              callback: (val) => formatCompact(val),
              font: { size: 10 }
            }
          }
        }
      }
    });

    // 2. Sub-Category Net Profit Bar Chart
    const subcatMap = {};
    data.forEach(d => {
      if (!subcatMap[d.sub]) subcatMap[d.sub] = 0;
      subcatMap[d.sub] += d.p;
    });

    const sortedSubcats = Object.entries(subcatMap)
      .sort((a, b) => a[1] - b[1]); // Ascending
    const subcatLabels = sortedSubcats.map(e => e[0]);
    const subcatProfits = sortedSubcats.map(e => e[1]);
    const subcatColors = subcatProfits.map(p => p < 0 ? '#f43f5e' : '#38bdf8');

    if (charts.subcategory) charts.subcategory.destroy();
    const ctxSubcat = document.getElementById('chart-subcategory').getContext('2d');
    charts.subcategory = new Chart(ctxSubcat, {
      type: 'bar',
      data: {
        labels: subcatLabels,
        datasets: [{
          label: 'Net Profit ($)',
          data: subcatProfits,
          backgroundColor: subcatColors,
          borderRadius: 4
        }]
      },
      options: {
        indexAxis: 'y',
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
          legend: { display: false },
          tooltip: {
            callbacks: {
              label: (ctx) => `Net Profit: ${formatCurrency(ctx.parsed.x)}`
            }
          }
        },
        scales: {
          x: {
            grid: { color: 'rgba(255, 255, 255, 0.05)' },
            ticks: { color: '#64748b', callback: (v) => formatCompact(v), font: { size: 10 } }
          },
          y: {
            grid: { display: false },
            ticks: { color: '#94a3b8', font: { size: 10 } }
          }
        }
      }
    });

    // 3. The "Discount Cliff" Bar Chart
    const tiers = ['0% (No Discount)', '1-10% (Low)', '11-20% (Moderate)', '>20% (High / Deep)'];
    const tierMetrics = {
      '0% (No Discount)': { s: 0, p: 0 },
      '1-10% (Low)': { s: 0, p: 0 },
      '11-20% (Moderate)': { s: 0, p: 0 },
      '>20% (High / Deep)': { s: 0, p: 0 }
    };

    data.forEach(d => {
      if (tierMetrics[d.tier]) {
        tierMetrics[d.tier].s += d.s;
        tierMetrics[d.tier].p += d.p;
      }
    });

    const tierMargins = tiers.map(t => {
      const s = tierMetrics[t].s;
      const p = tierMetrics[t].p;
      return s > 0 ? (p / s) * 100 : 0;
    });

    const tierColors = ['#10b981', '#38bdf8', '#f59e0b', '#f43f5e'];

    if (charts.discount) charts.discount.destroy();
    const ctxDiscount = document.getElementById('chart-discount').getContext('2d');
    charts.discount = new Chart(ctxDiscount, {
      type: 'bar',
      data: {
        labels: ['0% (Full Price)', '1 - 10%', '11 - 20%', '> 20% (High)'],
        datasets: [{
          label: 'Profit Margin %',
          data: tierMargins,
          backgroundColor: tierColors,
          borderRadius: 6
        }]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
          legend: { display: false },
          tooltip: {
            callbacks: {
              label: (ctx) => `Margin: ${ctx.parsed.y.toFixed(1)}%`
            }
          }
        },
        scales: {
          x: {
            grid: { display: false },
            ticks: { color: '#94a3b8', font: { size: 10 } }
          },
          y: {
            grid: { color: 'rgba(255, 255, 255, 0.05)' },
            ticks: { color: '#64748b', callback: (v) => v + '%', font: { size: 10 } }
          }
        }
      }
    });

    // 4. Regional Performance Comparison
    const regMap = { West: { s: 0, p: 0 }, East: { s: 0, p: 0 }, Central: { s: 0, p: 0 }, South: { s: 0, p: 0 } };
    data.forEach(d => {
      if (regMap[d.reg]) {
        regMap[d.reg].s += d.s;
        regMap[d.reg].p += d.p;
      }
    });

    const regLabels = Object.keys(regMap);
    const regSales = regLabels.map(r => regMap[r].s);
    const regProfits = regLabels.map(r => regMap[r].p);

    if (charts.region) charts.region.destroy();
    const ctxRegion = document.getElementById('chart-region').getContext('2d');
    charts.region = new Chart(ctxRegion, {
      type: 'bar',
      data: {
        labels: regLabels,
        datasets: [
          { label: 'Sales ($)', data: regSales, backgroundColor: 'rgba(56, 189, 248, 0.8)', borderRadius: 4 },
          { label: 'Profit ($)', data: regProfits, backgroundColor: 'rgba(16, 185, 129, 0.8)', borderRadius: 4 }
        ]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
          legend: { labels: { color: '#94a3b8', font: { size: 10 } } },
          tooltip: {
            callbacks: {
              label: (ctx) => `${ctx.dataset.label}: ${formatCurrency(ctx.parsed.y)}`
            }
          }
        },
        scales: {
          x: { grid: { display: false }, ticks: { color: '#94a3b8', font: { size: 10 } } },
          y: { grid: { color: 'rgba(255, 255, 255, 0.05)' }, ticks: { color: '#64748b', callback: (v) => formatCompact(v), font: { size: 10 } } }
        }
      }
    });

    // 5. Customer Segment Breakdown
    const segMap = { Consumer: 0, Corporate: 0, 'Home Office': 0 };
    data.forEach(d => {
      if (segMap[d.seg] !== undefined) segMap[d.seg] += d.s;
    });

    if (charts.segment) charts.segment.destroy();
    const ctxSegment = document.getElementById('chart-segment').getContext('2d');
    charts.segment = new Chart(ctxSegment, {
      type: 'doughnut',
      data: {
        labels: Object.keys(segMap),
        datasets: [{
          data: Object.values(segMap),
          backgroundColor: ['#38bdf8', '#06b6d4', '#8b5cf6'],
          borderColor: '#111827',
          borderWidth: 2
        }]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
          legend: { position: 'bottom', labels: { color: '#94a3b8', font: { size: 10 } } },
          tooltip: {
            callbacks: {
              label: (ctx) => `${ctx.label}: ${formatCurrency(ctx.parsed)}`
            }
          }
        },
        cutout: '70%'
      }
    });
  }

  // Update Product Table (Top Contributors vs Loss Makers)
  function updateProductTable(data) {
    const prodMap = {};
    data.forEach(d => {
      if (!prodMap[d.prod]) {
        prodMap[d.prod] = {
          name: d.prod,
          cat: d.cat,
          sub: d.sub,
          sales: 0,
          profit: 0
        };
      }
      prodMap[d.prod].sales += d.s;
      prodMap[d.prod].profit += d.p;
    });

    const prodList = Object.values(prodMap);
    if (state.productTab === 'top') {
      prodList.sort((a, b) => b.profit - a.profit);
    } else {
      prodList.sort((a, b) => a.profit - b.profit);
    }

    const items = prodList.slice(0, 5);
    elProductTableBody.innerHTML = '';

    items.forEach((p, idx) => {
      const margin = p.sales > 0 ? (p.profit / p.sales) * 100 : 0;
      const isPositive = p.profit >= 0;
      const tr = document.createElement('tr');
      tr.innerHTML = `
        <td style="font-weight: 600; color: #f8fafc;">#${idx + 1} ${p.name}</td>
        <td><span style="color: #94a3b8;">${p.cat}</span> &rsaquo; ${p.sub}</td>
        <td style="font-weight: 600;">${formatCurrency(p.sales)}</td>
        <td style="font-weight: 700; color: ${isPositive ? '#10b981' : '#f43f5e'};">${formatCurrency(p.profit)}</td>
        <td>
          <span class="badge-profit ${isPositive ? 'positive' : 'negative'}">
            ${margin.toFixed(1)}%
          </span>
        </td>
      `;
      elProductTableBody.appendChild(tr);
    });
  }

  // Master render function
  function render() {
    const filtered = getFilteredData();
    updateKPIs(filtered);
    updateCharts(filtered);
    updateProductTable(filtered);
  }

  // Event Listeners for Filters
  elRegionFilter.addEventListener('change', (e) => {
    state.region = e.target.value;
    render();
  });

  elSegmentFilter.addEventListener('change', (e) => {
    state.segment = e.target.value;
    render();
  });

  elYearFilter.addEventListener('change', (e) => {
    state.year = e.target.value;
    render();
  });

  elResetBtn.addEventListener('click', () => {
    state.region = 'All';
    state.segment = 'All';
    state.year = 'All';
    elRegionFilter.value = 'All';
    elSegmentFilter.value = 'All';
    elYearFilter.value = 'All';
    render();
  });

  elTabTop.addEventListener('click', () => {
    state.productTab = 'top';
    elTabTop.classList.add('active');
    elTabBottom.classList.remove('active');
    updateProductTable(getFilteredData());
  });

  elTabBottom.addEventListener('click', () => {
    state.productTab = 'bottom';
    elTabBottom.classList.add('active');
    elTabTop.classList.remove('active');
    updateProductTable(getFilteredData());
  });

  // Initial load
  render();
});
