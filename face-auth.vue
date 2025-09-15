<template>
  <div class="face-auth">
    <el-card>
      <template #header>
        <span>行为检测</span>
      </template>
      <!-- 上半部分：左右两栏 -->
      <div class="auth-top">
        <!-- 左：视频画面 -->
        <div class="camera-box">
          <video ref="videoRef" :src="videoUrl" controls autoplay muted></video>
        </div>
        <!-- 右：识别结果 -->
        <div class="info-box" v-if="selectedEventInfo">
          <div class="info-header">
            <h3>识别结果详情</h3>
          </div>
          <div class="info-content">
            <div class="info-row">
              <span class="info-label">ID</span>
              <span class="info-value">{{ selectedEventInfo.id }}</span>
            </div>
            <div class="info-row">
              <span class="info-label">事件类型</span>
              <span class="info-value">{{ selectedEventInfo.event_type }}</span>
            </div>
            <div class="info-row">
              <span class="info-label">摄像头ID</span>
              <span class="info-value">{{ selectedEventInfo.camera_id }}</span>
            </div>
            <div class="info-row">
              <span class="info-label">时间</span>
              <span class="info-value">{{ new Date(selectedEventInfo.time).toLocaleString() }}</span>
            </div>
            <div class="info-row">
              <span class="info-label">置信度</span>
              <span class="info-value confidence">{{ (selectedEventInfo.confidence * 100).toFixed(2) }}%</span>
            </div>
            <div class="info-row">
              <span class="info-label">人员ID</span>
              <span class="info-value" :class="{ 'unknown': selectedEventInfo.person_id === null }">
                {{ selectedEventInfo.person_id !== null ? selectedEventInfo.person_id : '未知' }}
              </span>
            </div>
          </div>
        </div>
        <div class="info-box empty-state" v-else>
          <div class="empty-content">
            <i class="el-icon-info"></i>
            <p>请选择事件查看详情</p>
          </div>
        </div>
      </div>
      <!-- 下半部分：表格区域 -->
      <el-table
          :data="eventList"
          height="200"
          @row-click="({ id }) => selectEvent(id)"
          :row-class-name="({ id }) => id === selectedEventId ? 'selected-row' : ''"
      >
        <el-table-column prop="id" label="ID" width="80"/>
        <el-table-column prop="event_type" label="事件类型"/>
        <el-table-column prop="confidence" label="置信度"/>
        <el-table-column prop="time" label="识别时间"/>
      </el-table>
    </el-card>
  </div>
</template>

<script setup lang="ts">
import {ref, onMounted} from 'vue'
import {getEventDetail, getEventList} from '@/api/event'

const videoRef = ref<HTMLVideoElement | null>(null)
const videoUrl = ref('')  // 绑定视频路径
const eventList = ref<any[]>([]) // 事件列表数据
const selectedEventId = ref<number | null>(null)
const selectedEventInfo = ref<any | null>(null)

// 加载列表
async function loadEventList() {
  try {
    eventList.value = await getEventList()
  } catch (e) {
    console.error('加载事件列表失败', e)
  }
}

// 选中事件，加载详情和视频
async function selectEvent(id: number) {
  try {
    selectedEventId.value = id
    const event = await getEventDetail(id)
    selectedEventInfo.value = event
    videoUrl.value = `http://8.152.101.217/${event.video_clip_path}`
    if (videoRef.value) {
      videoRef.value.load()
      videoRef.value.play().catch(console.error)
    }
  } catch (e) {
    console.error('加载事件详情失败', e)
  }
}

// 初始化时先加载列表，然后默认选中第一条（如果有）
onMounted(async () => {
  await loadEventList()
  if (eventList.value.length > 0) {
    await selectEvent(eventList.value[0].id)
  }
})
</script>

<style scoped>
.face-auth {
  padding: 16px;
}

.auth-top {
  display: flex;
  gap: 24px;
  margin-bottom: 24px;
}

.camera-box,
.info-box {
  flex: 1;
  min-height: 280px;
  border: 1px solid #e4e7ed;
  border-radius: 8px;
  background: #ffffff;
  overflow: hidden;
}

.camera-box {
  padding: 12px;
  background: #fafafa;
  display: flex;
  flex-direction: column;
}

video {
  width: 100%;
  height: auto;
  border-radius: 8px;
}

.info-box {
  display: flex;
  flex-direction: column;
}

.info-header {
  background: #f5f7fa;
  padding: 16px 20px;
  border-bottom: 1px solid #e4e7ed;
}

.info-header h3 {
  margin: 0;
  font-size: 16px;
  font-weight: 600;
  color: #303133;
}

.info-content {
  flex: 1;
  display: flex;
  flex-direction: column;
}

.info-row {
  display: flex;
  align-items: center;
  padding: 16px 20px;
  border-bottom: 1px solid #f0f2f5;
  transition: background-color 0.2s;
}

.info-row:hover {
  background-color: #f8f9fa;
}

.info-row:last-child {
  border-bottom: none;
}

.info-label {
  flex: 0 0 80px;
  font-weight: 600;
  color: #606266;
  font-size: 14px;
}

.info-value {
  flex: 1;
  color: #303133;
  font-size: 14px;
  word-break: break-all;
}

.info-value.confidence {
  color: #67c23a;
  font-weight: 600;
}

.info-value.unknown {
  color: #909399;
  font-style: italic;
}

/* 空状态样式 */
.empty-state {
  justify-content: center;
  align-items: center;
}

.empty-content {
  text-align: center;
  color: #909399;
}

.empty-content i {
  font-size: 48px;
  margin-bottom: 16px;
  display: block;
}

.empty-content p {
  margin: 0;
  font-size: 14px;
}

/* 表格选中行样式 */
:deep(.selected-row) {
  background-color: #ecf5ff !important;
}

:deep(.selected-row:hover > td) {
  background-color: #ecf5ff !important;
}
</style>
