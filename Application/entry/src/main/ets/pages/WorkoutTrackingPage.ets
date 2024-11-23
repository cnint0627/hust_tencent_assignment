// entry/src/main/ets/pages/WorkoutTrackingPage.ets
import { router } from "@kit.ArkUI"
import { WorkoutType } from "../common/WorkoutType"
import { WorkoutRecord } from "../common/WorkoutRecord"
import promptAction from '@ohos.promptAction'
import geoLocationManager from '@ohos.geoLocationManager'
import bundleManager from '@ohos.bundle.bundleManager'
import abilityAccessCtrl, { Permissions } from '@ohos.abilityAccessCtrl'
import { BusinessError } from '@ohos.base'
import common from '@ohos.app.ability.common'

interface Location {
  latitude: number;
  longitude: number;
}

@Entry
@Component
export struct WorkoutTrackingPage {
  @State private isWorking: boolean = false
  @State private isPaused: boolean = false
  @State private time: number = 0
  @State private distance: number = 0
  @State private workoutType: WorkoutType = { id: 1, name: "跑步", icon: ""}
  @State private hasLocationPermission: boolean = false
  @State private isMapLoading: boolean = true
  @State private isMapInitialized: boolean = false
  @State private currentLocation: Location | null = null // 初始值设为 null
  @State private isLocationReady: boolean = false // 新增状态标记位置是否已获取

  private webController: WebController = new WebController()
  private readonly AMAP_KEY = '8d85bdb1ee481d086e7bca7c3923ace4'  // 高德api key
  private timerId: number = -1
  private locationTimerId: number = -1
  private lastLocation: Location | null = null
  onBack?: () => void

  // 添加新的方法用于保存运动记录
  async saveWorkoutRecord() {
    try {
      // 从地图中获取轨迹段数据
      this.webController.runJavaScript({ script: 'getAllSegments();' })
        .then(async (segments: Array<Array<[number, number]>>) => {
          const record: WorkoutRecord = {
            workoutType: this.workoutType.name,
            totalTime: this.time,
            totalDistance: this.distance,
            averageSpeed: this.time > 0 ? (this.distance / (this.time / 3600)) : 0,
            createTime: new Date(),
            segments: segments
          };

          // 调用云函数保存记录

        });
    } catch (error) {
      console.error('[Workout] Failed to get segments:', error);
    }
  }

  getMapHtml() {
    if (!this.currentLocation) {
      return '';
    }

    return `
    <!DOCTYPE html>
    <html>
      <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=0">
        <title>运动轨迹</title>
        <style>
          html, body, #container {
            width: 100%;
            height: 100%;
            margin: 0;
            padding: 0;
          }
        </style>
        <script type="text/javascript" src="https://webapi.amap.com/maps?v=2.0&key=${this.AMAP_KEY}"></script>
      </head>
      <body>
        <div id="container"></div>
        <script>
          let map = null;
          let marker = null;
          let polylines = []; // 改为存储多段轨迹
          let currentPath = []; // 当前正在记录的轨迹段
          let isInitialized = false;
          let isTracking = false;

          function initMap(lat, lng) {
            try {
              console.log('Initializing map with:', lat, lng);
              map = new AMap.Map('container', {
                zoom: 15,
                center: [lng, lat]
              });

              marker = new AMap.Marker({
                position: [lng, lat],
                icon: 'https://webapi.amap.com/theme/v1.3/markers/n/mark_b.png',
                map: map
              });

              isInitialized = true;
              console.log('Map initialized successfully');
            } catch(e) {
              console.error('Map initialization failed:', e);
            }
          }

          // 创建新的轨迹线段
          function createNewPolyline() {
            const polyline = new AMap.Polyline({
              map: map,
              path: [],
              strokeColor: "#FF0000",
              strokeWeight: 3,
              strokeOpacity: 1
            });
            polylines.push(polyline);
            return polyline;
          }

          // 开始运动
          window.startTracking = function() {
            isTracking = true;
            currentPath = [];
            // 创建新的轨迹线段
            createNewPolyline();
            // 如果有当前位置，将其作为新轨迹段的起点
            if (marker) {
              const position = marker.getPosition();
              currentPath.push(position);
              polylines[polylines.length - 1].setPath(currentPath);
            }
            console.log('New tracking segment started');
          }

          // 暂停运动
          window.pauseTracking = function() {
            isTracking = false;
            // 保存当前轨迹段
            currentPath = [];
            console.log('Tracking paused');
          }

          // 继续运动
          window.resumeTracking = function() {
            isTracking = true;
            currentPath = [];
            // 创建新的轨迹线段
            createNewPolyline();
            // 将当前位置作为新轨迹段的起点
            if (marker) {
              const position = marker.getPosition();
              currentPath.push(position);
              polylines[polylines.length - 1].setPath(currentPath);
            }
            console.log('Tracking resumed with new segment');
          }

          // 停止运动
          window.stopTracking = function() {
            isTracking = false;
            currentPath = [];
            // 清除所有轨迹
            polylines.forEach(polyline => {
              polyline.setMap(null);
            });
            polylines = [];
            console.log('Tracking stopped, all segments cleared');
          }

          window.updateLocation = function(lat, lng) {
            try {
              console.log('Updating location:', lat, lng);
              if (!isInitialized) {
                initMap(lat, lng);
                return;
              }

              const position = [lng, lat];
              marker.setPosition(position);

              // 只有在运动且未暂停时才添加轨迹点
              if (isTracking && polylines.length > 0) {
                currentPath.push(position);
                polylines[polylines.length - 1].setPath(currentPath);
              }

              map.setCenter(position);
              console.log('Location updated successfully');
            } catch(e) {
              console.error('Location update failed:', e);
            }
          }

          // 获取所有轨迹段数据
          window.getAllSegments = function() {
            try {
              const segments = polylines.map(polyline => {
                return polyline.getPath().map(point => [point.getLng(), point.getLat()]);
              });
              return JSON.stringify(segments);
            } catch(e) {
              console.error('Failed to get segments:', e);
              return '[]';
            }
          }

          initMap(${this.currentLocation.latitude}, ${this.currentLocation.longitude});
        </script>
      </body>
    </html>
  `;
  }

  // 修改运动控制相关的方法
  startWorkout() {
    this.isWorking = true;
    this.isPaused = false;
    this.startTimer();
    // 开始轨迹记录
    this.webController.runJavaScript({ script: 'startTracking();' });
  }

  pauseWorkout() {
    this.isPaused = true;
    this.stopTimer();
    // 暂停轨迹记录
    this.webController.runJavaScript({ script: 'pauseTracking();' });
  }

  resumeWorkout() {
    this.isPaused = false;
    this.startTimer();
    // 继续轨迹记录
    this.webController.runJavaScript({ script: 'resumeTracking();' });
  }

  stopWorkout() {
    this.isWorking = false;
    this.isPaused = false;
    this.stopTimer();
    // 停止轨迹记录
    this.webController.runJavaScript({ script: 'stopTracking();' });
  }

  async getCurrentGPSLocation(): Promise<Location | null> {
    try {
      const location = await geoLocationManager.getCurrentLocation()
      console.info(`[GPS] Got location - Lat: ${location.latitude}, Lng: ${location.longitude}`)
      return {
        latitude: location.latitude,
        longitude: location.longitude
      }
    } catch (error) {
      console.error('[GPS] Failed to get current location:', error)
      return null
    }
  }

  updateMap(location: Location) {
    try {
      const script = `updateLocation(${location.latitude}, ${location.longitude});`
      this.webController.runJavaScript({ script: script })
      console.info('[Map] Location update script executed')
    } catch (error) {
      console.error('[Map] Failed to execute location update script:', error)
    }
  }

  async startLocationTimer() {
    if (this.locationTimerId !== -1) {
      return
    }

    // 立即执行一次获取位置
    const initialLocation = await this.getCurrentGPSLocation()
    if (initialLocation) {
      this.currentLocation = initialLocation
      this.updateMap(initialLocation)
    }

    // 设置定时器持续更新位置
    this.locationTimerId = setInterval(async () => {
      try {
        const location = await this.getCurrentGPSLocation()
        if (location) {
          // 计算距离
          if (this.lastLocation && this.isWorking && !this.isPaused) {
            const segmentDistance = this.calculateDistance(
              this.lastLocation.latitude,
              this.lastLocation.longitude,
              location.latitude,
              location.longitude
            )
            this.distance += segmentDistance
            console.info(`[Distance] Segment: ${segmentDistance.toFixed(4)}km, Total: ${this.distance.toFixed(4)}km`)
          }

          this.lastLocation = location
          this.currentLocation = location
          this.updateMap(location)
        }
      } catch (error) {
        console.error('[Location Timer] Error:', error)
      }
    }, 1000)
  }

  stopLocationTimer() {
    if (this.locationTimerId !== -1) {
      clearInterval(this.locationTimerId)
      this.locationTimerId = -1
    }
  }

  aboutToAppear() {
    const params = router.getParams() as WorkoutType
    if (params) {
      this.workoutType = params
    }
    this.requestLocationPermission()
  }

  calculateDistance(lat1: number, lon1: number, lat2: number, lon2: number): number {
    const R = 6371; // Earth's radius in kilometers
    const dLat = this.deg2rad(lat2 - lat1);
    const dLon = this.deg2rad(lon2 - lon1);
    const a =
      Math.sin(dLat / 2) * Math.sin(dLat / 2) +
        Math.cos(this.deg2rad(lat1)) * Math.cos(this.deg2rad(lat2)) *
        Math.sin(dLon / 2) * Math.sin(dLon / 2);
    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    return R * c;
  }

  deg2rad(deg: number): number {
    return deg * (Math.PI / 180);
  }

  async requestLocationPermission() {
    try {
      const context = getContext(this) as common.UIAbilityContext
      const permissions: Array<Permissions> = ['ohos.permission.LOCATION']
      let atManager = abilityAccessCtrl.createAtManager()

      let result = await atManager.requestPermissionsFromUser(context, permissions)
      if (result.authResults.every(res => res === 0)) {
        console.info('Location permission granted')
        this.hasLocationPermission = true
        await this.initializeLocation() // 获取权限后立即初始化位置
      } else {
        console.warn('Location permission denied')
        promptAction.showToast({
          message: '请授予位置权限以使用运动跟踪功能',
          duration: 3000
        })
      }
    } catch (error) {
      console.error('Permission request failed:', error)
      promptAction.showToast({
        message: '获取位置权限失败',
        duration: 3000
      })
    }
  }

  // 新增初始化位置的方法
  async initializeLocation() {
    try {
      const location = await this.getCurrentGPSLocation()
      if (location) {
        this.currentLocation = location
        this.isLocationReady = true
        console.info('[GPS] Initial location set:', location)
        this.startLocationTimer() // 开始定时更新位置
      }
    } catch (error) {
      console.error('[GPS] Failed to initialize location:', error)
    }
  }

  startTimer() {
    if (this.timerId === -1) {
      this.timerId = setInterval(() => {
        this.time++
      }, 1000)
      console.info('Timer started')
    }
  }

  stopTimer() {
    if (this.timerId !== -1) {
      clearInterval(this.timerId)
      this.timerId = -1
      console.info('Timer stopped')
    }
  }

  formatTime(seconds: number): string {
    const hours = Math.floor(seconds / 3600)
    const minutes = Math.floor((seconds % 3600) / 60)
    const secs = seconds % 60
    return `${hours.toString().padStart(2, '0')}:${minutes.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}`
  }

  @Builder
  LoadingView() {
    Column() {
      LoadingProgress()
        .width(64)
        .height(64)
      Text('加载中...')
        .fontSize(16)
        .margin({ top: 8 })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }

  build() {
    Column() {
      // 修改返回按钮的处理逻辑
      Row() {
        Text('返回')
          .fontSize(24)
          .fontColor('#000000')
          .onClick(() => {
            if (this.isWorking) {
              AlertDialog.show({
                title: '确认退出？',
                message: '退出后运动记录将不会保存',
                alignment: DialogAlignment.Center,
                primaryButton: {
                  value: '取消',
                  action: () => {
                    console.info('[Navigation] Back cancelled')
                  }
                },
                secondaryButton: {
                  value: '确认',
                  action: () => {
                    console.info('[Navigation] Back confirmed')
                    this.stopTimer()
                    this.stopLocationTimer()
                    if (this.onBack) {
                      this.onBack()
                    }
                  }
                }
              })
            } else {
              if (this.onBack) {
                this.onBack()
              }
            }
          })
        Text(this.workoutType?.name)
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
      }
      .width('100%')
      .justifyContent(FlexAlign.Start)
      .padding(16)

      Stack() {
        if (this.hasLocationPermission && this.isLocationReady && this.currentLocation) {
          Web({
            src: 'data:text/html;charset=utf-8,' + encodeURIComponent(this.getMapHtml()),
            controller: this.webController
          })
            .width('100%')
            .height('100%')
            .domStorageAccess(true)
            .fileAccess(true)
            .imageAccess(true)
            .javaScriptAccess(true)
            .onPageBegin(() => {
              console.info('[Map] Page begin loading')
              this.isMapLoading = true
            })
            .onPageEnd(() => {
              console.info('[Map] Page finished loading')
              this.isMapLoading = false
              this.isMapInitialized = true
            })
            .onErrorReceive((err) => {
              console.error('[Map] Error:', err)
              promptAction.showToast({
                message: '地图加载失败，请检查网络连接',
                duration: 3000
              })
            })

          if (this.isMapLoading) {
            this.LoadingView()
          }
        } else if (!this.hasLocationPermission) {
          Column() {
            Text('需要位置权限')
              .fontSize(16)
            Button('授予权限')
              .onClick(() => this.requestLocationPermission())
          }
          .width('100%')
          .height('100%')
          .justifyContent(FlexAlign.Center)
        } else {
          this.LoadingView()
        }
      }
      .width('100%')
      .height('40%')
      .backgroundColor('#f5f5f5')

      Column() {
        Text(this.formatTime(this.time))
          .fontSize(40)
          .fontWeight(FontWeight.Bold)
          .margin({ top: 20, bottom: 20 })

        Row() {
          Column() {
            Text('距离')
              .fontSize(16)
            Text(`${this.distance.toFixed(2)} km`)
              .fontSize(24)
              .fontWeight(FontWeight.Bold)
          }
          .margin({ right: 40 })

          Column() {
            Text('配速')
              .fontSize(16)
            Text(this.time > 0 ? `${(this.distance / (this.time / 3600)).toFixed(2)} km/h` : '0.00 km/h')
              .fontSize(24)
              .fontWeight(FontWeight.Bold)
          }
        }
      }
      .padding(16)

      Row() {
        Button({
          type: ButtonType.Capsule,
          stateEffect: true
        }) {
          Row() {
            Image(this.isWorking && !this.isPaused ? '/common/pause.png' : '/common/play.png')
              .width(24)
              .height(24)
              .margin({ right: 8 })
            Text(this.isWorking && !this.isPaused ? '暂停' : '开始')
              .fontSize(16)
              .fontColor(Color.White)
          }
        }
        .width(120)
        .height(48)
        .backgroundColor(this.isWorking && !this.isPaused ? '#FFA500' : '#44ff44')
        .margin({ right: 16 })
        .onClick(() => {
          if (!this.isWorking) {
            console.info('[Workout] Starting workout')
            this.startWorkout()
          } else {
            if (this.isPaused) {
              console.info('[Workout] Resuming workout')
              this.resumeWorkout()
            } else {
              console.info('[Workout] Pausing workout')
              this.pauseWorkout()
            }
          }
        })

        // 修改停止按钮的处理逻辑
        Button({
          type: ButtonType.Capsule,
          stateEffect: true
        }) {
          Row() {
            Image('/common/stop.png')
              .width(24)
              .height(24)
              .margin({ right: 8 })
            Text('停止')
              .fontSize(16)
              .fontColor(Color.White)
          }
        }
        .width(120)
        .height(48)
        .backgroundColor('#ff4444')
        .onClick(() => {
          if (!this.isWorking) {
            return;
          }

          AlertDialog.show({
            title: '确认结束运动？',
            message: '运动数据将被保存',
            alignment: DialogAlignment.Center,
            primaryButton: {
              value: '取消',
              action: () => {
                console.info('[Workout] Stop cancelled')
              }
            },
            secondaryButton: {
              value: '确认',
              action: async () => {
                console.info('[Workout] Stopping workout')
                this.stopTimer()
                this.stopLocationTimer()

                // 先停止记录轨迹
                this.webController.runJavaScript({ script: 'stopTracking();' })

                // 保存运动记录
                await this.saveWorkoutRecord()

                if (this.onBack) {
                  this.onBack()
                }
              }
            }
          })
        })
      }
      .margin({ top: 40 })
      .width('100%')
      .justifyContent(FlexAlign.Center)
    }
    .width('100%')
    .height('100%')
  }

  aboutToDisappear() {
    console.info('[Cleanup] Cleaning up resources')
    this.stopTimer()
    this.stopLocationTimer()
  }
}