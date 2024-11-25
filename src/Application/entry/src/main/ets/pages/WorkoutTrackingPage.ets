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
import { WorkoutService } from "../services/WorkoutService"
import image from '@ohos.multimedia.image'
import web_webview from '@ohos.web.webview'

import cloud, { ProgressEvent, Storage } from '@hw-agconnect/cloud'
import fileIo from "@ohos.file.fs"

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
  @State private isLoading: boolean = false

  private webController: web_webview.WebviewController = new web_webview.WebviewController();
  private workoutService: WorkoutService = WorkoutService.getInstance();
  private readonly AMAP_KEY = '8d85bdb1ee481d086e7bca7c3923ace4'  // 高德api key
  private timerId: number = -1
  private locationTimerId: number = -1
  private lastLocation: Location | null = null
  private imagePackerApi = image.createImagePacker();
  private storage: Storage = cloud.storage();
  onBack?: () => void

  // 获取运动类型对应的图标
  getWorkoutTypeIcon(workoutType: string): Resource {
    switch (workoutType) {
      case '跑步':
        return $r('app.media.ic_run');
      case '骑车':
        return $r('app.media.ic_bike');
      case '健走':
        return $r('app.media.ic_walk');
      case '游泳':
        return $r('app.media.ic_swim');
      default:
        return $r('app.media.ic_run');
    }
  }

  // 添加新的方法用于保存运动记录
  async saveWorkoutRecord() {
    try {
      this.isLoading = true;

      // 获取地图快照并上传到云存储
      let snapshotUrl: string;
      try {
        snapshotUrl = await this.saveMapSnapshot();
      } catch (error) {
        snapshotUrl = "";
        console.error('[Map] Failed to save snapshot:', error);
      }

      if (snapshotUrl === '') {
        promptAction.showToast({
          message: '轨迹上传失败，请重试',
          duration: 3000
        })
        return;
      }

      const workoutRecord: WorkoutRecord = {
        workoutType: this.workoutType.name,
        totalTime: this.time,
        totalDistance: parseFloat(this.distance.toFixed(4)),
        averageSpeed: this.time > 0 ? parseFloat((this.distance / (this.time / 3600)).toFixed(4)) : 0,
        snapshotUrl: snapshotUrl,
        uid: "",
        recordId: 0,
        createTime: new Date(),
      };

      // 调用服务层保存记录
      let res: boolean = await this.workoutService.saveWorkoutRecord(workoutRecord);
      if (res) {
        console.info('记录上传成功！')
        promptAction.showToast({
          message: '记录保存成功~',
          duration: 3000
        })
        router.back()  // 使用 router.back() 返回上一页
      } else {
        console.error('记录上传失败！')
        promptAction.showToast({
          message: '记录保存失败，请检查网络状态',
          duration: 3000
        })
      }
    } catch (error) {
      console.error('[Workout] Failed to get segments:', error);
    } finally {
      this.isLoading = false;
    }
  }

  // 保存地图轨迹快照
  async saveMapSnapshot(): Promise<string> {
    try {
      console.info('[Map] Starting snapshot process');

      await this.webController.runJavaScript('saveMapSnapshot();');

      await new Promise<void>((resolve: () => void): void => {
        setTimeout(resolve, 5000);
      });

      const context = getContext(this) as Context;
      const filesDir = context.cacheDir;
      console.log("[Map] " + filesDir)
      const fileName = `map_snapshot_temp.png`;
      const filePath = `${filesDir}/${fileName}`;

      return new Promise<string>((resolve, reject) => {
        try {
          this.webController.webPageSnapshot(
            {
              id: "mapSnapshot",
              size: { width: 800, height: 600 }
            },
            async (error: BusinessError | null, result?: web_webview.SnapshotResult) => {
              if (error) {
                console.error(`[Map] Snapshot error - Code: ${error.code}, Message: ${error.message}`);
                resolve('');
                return;
              }

              if (result) {
                // 上传至云存储默认实例
                let packOpts: image.PackingOption = { format: "image/jpeg", quality: 50 }
                let file = fileIo.openSync(filePath, fileIo.OpenMode.CREATE | fileIo.OpenMode.READ_WRITE);
                const imagePackerApi: image.ImagePacker = image.createImagePacker();
                // 注意文件写入的过程是异步的，需要等待执行完再上传，否则文件还没有写好上传的就是之前的cache
                await imagePackerApi.packToFile(result.imagePixelMap, file.fd, packOpts);

                let cloudPath = `snapshots/${Date.now()}.jpeg`
                this.storage.upload({
                  localPath: filePath,
                  cloudPath: cloudPath,
                  onUploadProgress: (p: ProgressEvent) => {
                    console.log(`onUploadProgress:bytes:${p.loaded} total:${p.total}`)
                  }
                }).then(res=>{
                  console.log('[Map] snapshot saved success');
                  resolve(cloudPath);
                }).catch((err: Error)=> {
                  console.error('[Map] snapshot saved failed: ', err);
                  resolve('');
                });
              } else {
                console.error('[Map] No snapshot result');
                resolve('');
              }
            }
          );
        } catch (error) {
          console.error('[Map] Failed to take snapshot:', error instanceof Error ? error.message : error);
          resolve('');
        }
      });

    } catch (error) {
      console.error('[Map] Failed to save snapshot:', error instanceof Error ? error.message : error);
      return '';
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
          html, body {
            width: 100%;
            height: 100%;
            margin: 0;
            padding: 0;
          }
          #container {
            width: 100%;
            height: 100%;
            background: #fff;
          }
          #snapshot-container {
            position: fixed;
            width: 800px;
            height: 600px;
            top: -9999px;
            left: -9999px;
            background: #fff;
            z-index: -1;
            pointer-events: none;
          }
          // #debug-info {
          //   position: fixed;
          //   top: 10px;
          //   left: 10px;
          //   background: rgba(255,255,255,0.8);
          //   padding: 10px;
          //   z-index: 1000;
          //   font-size: 12px;
          //   max-height: 150px;
          //   overflow-y: auto;
          // }
          .amap-logo {
            display: none !important;
          }
          .amap-copyright {
            display: none !important;
          }
        </style>
        <script src="https://webapi.amap.com/maps?v=2.0&key=${this.AMAP_KEY}"></script>
        <script src="https://html2canvas.hertzen.com/dist/html2canvas.min.js"></script>
      </head>
      <body>
        <div id="container"></div>
        <div id="snapshot-container"></div>
        <div id="debug-info"></div>
        <script>
          let map = null;
          let marker = null;
          let polylines = [];
          let currentPath = [];
          let isInitialized = false;
          let isTracking = false;
          let snapshotMap = null;

          function log(message) {
            // const debugInfo = document.getElementById('debug-info');
            // const time = new Date().toLocaleTimeString();
            // debugInfo.innerHTML += \`[\${time}] \${message}<br>\`;
            // console.log(message);
          }

          function initMap(lat, lng) {
            try {
              log(\`Initializing map at [\${lat}, \${lng}]\`);
              map = new AMap.Map('container', {
                zoom: 15,
                center: [lng, lat],
                resizeEnable: true,
                showLabel: false
              });

              marker = new AMap.Marker({
                position: [lng, lat],
                icon: 'https://webapi.amap.com/theme/v1.3/markers/n/mark_b.png',
                map: map
              });

              isInitialized = true;
              log('Map initialized successfully');
            } catch(e) {
              log(\`Map initialization failed: \${e.message}\`);
            }
          }

          function createSnapshotMap(center, zoom, bounds) {
            try {
              log('Creating snapshot map');
              const snapshotContainer = document.getElementById('snapshot-container');
              const newMap = new AMap.Map(snapshotContainer, {
                zoom: zoom,
                center: center,
                resizeEnable: false,
                showLabel: false,
                dragEnable: false,
                zoomEnable: false,
                keyboardEnable: false,
                doubleClickZoom: false,
                scrollWheel: false,
                showIndoorMap: false
              });

              // 设置视野范围
              newMap.setBounds(bounds, {
                padding: [50, 50, 50, 50]
              });

              return newMap;
            } catch(e) {
              log(\`Snapshot map creation failed: \${e.message}\`);
              return null;
            }
          }

          window.startTracking = function() {
            isTracking = true;
            currentPath = [];
            createNewPolyline();
            if (marker) {
              const position = marker.getPosition();
              currentPath.push(position);
              polylines[polylines.length - 1].setPath(currentPath);
            }
            log('Started new tracking segment');
          }

          window.pauseTracking = function() {
            isTracking = false;
            currentPath = [];
            log('Tracking paused');
          }

          window.resumeTracking = function() {
            isTracking = true;
            currentPath = [];
            createNewPolyline();
            if (marker) {
              const position = marker.getPosition();
              currentPath.push(position);
              polylines[polylines.length - 1].setPath(currentPath);
            }
            log('Tracking resumed');
          }

          window.stopTracking = function() {
            isTracking = false;
            currentPath = [];
            log('Tracking stopped');
          }

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

          window.updateLocation = function(lat, lng) {
            try {
              if (!isInitialized) {
                initMap(lat, lng);
                return;
              }

              const position = [lng, lat];
              marker.setPosition(position);

              if (isTracking && polylines.length > 0) {
                currentPath.push(position);
                polylines[polylines.length - 1].setPath(currentPath);
              }

              map.setCenter(position);
              log(\`Location updated to [\${lat}, \${lng}]\`);
            } catch(e) {
              log(\`Location update failed: \${e.message}\`);
            }
          }

          window.saveMapSnapshot = function() {
            try {
              log('Starting map snapshot process');

              // If no polylines exist, return
              if (!polylines || polylines.length === 0) {
                log('No tracking data to snapshot');
                return;
              }

              // Collect all points from all polylines
              let allPoints = [];
              polylines.forEach(polyline => {
                const path = polyline.getPath();
                allPoints = allPoints.concat(path);
              });

              if (allPoints.length === 0) {
                log('No points found in polylines');
                return;
              }

              // Calculate bounds of all points
              let bounds = new AMap.Bounds(allPoints[0], allPoints[0]);
              allPoints.forEach(point => {
                bounds.extend(point);
              });

              // Add padding to bounds
              const padding = 50;
              const northEast = bounds.getNorthEast();
              const southWest = bounds.getSouthWest();
              const extendedBounds = new AMap.Bounds(
                new AMap.LngLat(
                  southWest.getLng() - padding * 0.0001,
                  southWest.getLat() - padding * 0.0001
                ),
                new AMap.LngLat(
                  northEast.getLng() + padding * 0.0001,
                  northEast.getLat() + padding * 0.0001
                )
              );

              // Fit map to bounds
              map.setBounds(extendedBounds, {
                padding: [50, 50, 50, 50]
              });

              log('Map view adjusted for snapshot');
            } catch(e) {
              log(\`Snapshot preparation failed: \${e.message}\`);
            }
          }

          // 初始化地图
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
    this.webController.runJavaScript('startTracking();');
  }

  pauseWorkout() {
    this.isPaused = true;
    this.stopTimer();
    // 暂停轨迹记录
    this.webController.runJavaScript('pauseTracking();');
  }

  resumeWorkout() {
    this.isPaused = false;
    this.startTimer();
    // 继续轨迹记录
    this.webController.runJavaScript('resumeTracking();');
  }

  stopWorkout() {
    this.isWorking = false;
    this.isPaused = false;
    this.stopTimer();
    // 停止轨迹记录
    this.webController.runJavaScript('stopTracking();');
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
      this.webController.runJavaScript(script)
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

  @Styles
  cardStyle() {
    .width('92%')
    .padding(16)
    .backgroundColor(Color.White)
    .borderRadius(16)
    .shadow({
      radius: 8,
      color: '#1A000000',
      offsetX: 2,
      offsetY: 4
    })
  }

  @Builder
  StatusBadge() {
    Row() {
      Circle({ width: 8, height: 8 })
        .fill(this.isWorking && !this.isPaused ? '#4CD964' : '#FF9500')
        .margin({ right: 6 })
      Text(this.isWorking ? (this.isPaused ? '已暂停' : '运动中') : '未开始')
        .fontSize(14)
        .fontColor(this.isWorking && !this.isPaused ? '#4CD964' : '#FF9500')
    }
    .padding(8)
    .borderRadius(12)
    .backgroundColor(this.isWorking && !this.isPaused ? '#E6F9E8' : '#FFF5E6')
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
    Stack() {
      Column() {
        // 顶部导航栏
        Row() {
          Row() {
            Button() {
              Row() {
                Image($r('app.media.ic_back'))
                  .width(24)
                  .height(24)
                  .margin({ right: 4 })
                Text('返回')
                  .fontSize(16)
                  .fontColor('#333333')
              }
            }
            .backgroundColor(Color.Transparent)
            .height(36)
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
                      router.back()
                    }
                  }
                })
              } else {
                router.back()
              }
            })
          }

          Row() {
            Image(this.getWorkoutTypeIcon(this.workoutType.name))
              .width(24)
              .height(24)
              .margin({ right: 8 })
            Text(this.workoutType?.name)
              .fontSize(18)
              .fontWeight(FontWeight.Medium)
              .fontColor('#333333')
          }

          this.StatusBadge()
        }
        .width('100%')
        .justifyContent(FlexAlign.SpaceBetween)
        .alignItems(VerticalAlign.Center)
        .padding({ left: 16, right: 16, top: 12, bottom: 12 })
        .backgroundColor(Color.White)
        .shadow({
          radius: 12,
          color: '#0A000000',
          offsetY: 2
        })

        // 地图区域
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
                this.isMapLoading = true
              })
              .onPageEnd(() => {
                this.isMapLoading = false
                this.isMapInitialized = true
              })
              .onErrorReceive((err) => {
                console.error('[Map] Error:', err.error.getErrorInfo())
              })

            if (this.isMapLoading) {
              this.LoadingView()
            }
          } else if (!this.hasLocationPermission) {
            Column() {
              Image(0)
                .width(64)
                .height(64)
                .margin({ bottom: 16 })
              Text('需要位置权限')
                .fontSize(16)
                .fontColor('#666666')
                .margin({ bottom: 12 })
              Button('授予权限', { type: ButtonType.Capsule })
                .backgroundColor('#007DFF')
                .width(140)
                .height(40)
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
        .height('45%')
        .backgroundColor('#F5F5F5')
        .margin({ bottom: 16 })

        // 运动数据展示区域
        Column() {
          Row() {
            Image($r('app.media.ic_timer'))
              .width(28)
              .height(28)
              .margin({ right: 8 })
            Text(this.formatTime(this.time))
              .fontSize(48)
              .fontWeight(FontWeight.Bold)
              .fontColor('#333333')
          }
          .margin({ top: 8, bottom: 24 })

          Row() {
            Column() {
              Text('总距离')
                .fontSize(14)
                .fontColor('#666666')
                .margin({ bottom: 4 })
              Row() {
                Image($r('app.media.ic_distance'))
                  .width(24)
                  .height(24)
                  .margin({ right: 8 })
                  .objectFit(ImageFit.Contain)
                Text(`${this.distance.toFixed(2)}`)
                  .fontSize(32)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#333333')
              }
              Text('公里')
                .fontSize(14)
                .fontColor('#666666')
                .margin({ top: 4 })
            }.layoutWeight(1)

            Divider()
              .vertical(true)
              .height(80)
              .color('#EEEEEE')
              .strokeWidth(1)

            Column() {
              Text('平均配速')
                .fontSize(14)
                .fontColor('#666666')
                .margin({ bottom: 4 })
              Row() {
                Image($r('app.media.ic_speed'))
                  .width(24)
                  .height(24)
                  .margin({ right: 8 })
                  .objectFit(ImageFit.Contain)
                Text(this.time > 0 ? `${(this.distance / (this.time / 3600)).toFixed(1)}` : '0.0')
                  .fontSize(32)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#333333')
              }
              Text('公里/小时')
                .fontSize(14)
                .fontColor('#666666')
                .margin({ top: 4 })
            }.layoutWeight(1)

          }
          .width('100%')
          .padding({ left: 16, right: 16 })
        }
        .cardStyle()
        .margin({ bottom: 24 })

        // 控制按钮区域
        Row() {
          Button({
            type: ButtonType.Capsule,
            stateEffect: true
          }) {
            Row() {
              Image(this.isWorking && !this.isPaused ? $r('app.media.ic_pause') : $r('app.media.ic_play'))
                .width(24)
                .height(24)
                .margin({ right: 8 })
              Text(this.isWorking && !this.isPaused ? '暂停' : '开始')
                .fontSize(16)
                .fontColor(Color.White)
                .fontWeight(FontWeight.Medium)
            }
          }
          .width(150)
          .height(50)
          .backgroundColor(this.isWorking && !this.isPaused ? '#FF9500' : '#4CD964')
          .margin({ right: 16 })
          .onClick(() => {
            if (!this.isWorking) {
              this.startWorkout()
            } else {
              if (this.isPaused) {
                this.resumeWorkout()
              } else {
                this.pauseWorkout()
              }
            }
          })

          Button({
            type: ButtonType.Capsule,
            stateEffect: true
          }) {
            Row() {
              Image($r('app.media.ic_stop'))
                .width(24)
                .height(24)
                .margin({ right: 8 })
              Text('结束')
                .fontSize(16)
                .fontColor(Color.White)
                .fontWeight(FontWeight.Medium)
            }
          }
          .width(150)
          .height(50)
          .backgroundColor('#FF3B30')
          .onClick(() => {
            if (!this.isWorking) {
              router.back()
              return
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
                  this.stopTimer()
                  this.stopLocationTimer()
                  this.webController.runJavaScript('pauseTracking();')
                  await this.saveWorkoutRecord()
                }
              }
            })
          })
        }
        .width('100%')
        .justifyContent(FlexAlign.Center)
        .margin({ bottom: 32 })
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#F5F5F5')

      // 加载指示器遮罩
      if (this.isLoading) {
        Column() {
          LoadingProgress()
            .color('#007DFF')
            .width(32)
            .height(32)
          Text('正在保存...')
            .fontSize(14)
            .fontColor('#007DFF')
            .margin({ top: 12 })
        }
        .width('100%')
        .height('100%')
        .backgroundColor('#80FFFFFF')
        .justifyContent(FlexAlign.Center)
        .zIndex(999)
      }
    }
  }


  aboutToDisappear() {
    console.info('[Cleanup] Cleaning up resources')
    this.stopTimer()
    this.stopLocationTimer()
  }
}