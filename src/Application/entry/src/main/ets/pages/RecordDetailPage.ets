// entry/src/main/ets/pages/RecordDetailPage.ets
import { WorkoutRecord } from '../common/WorkoutRecord';
import router from '@ohos.router';
import cloud, { Storage } from '@hw-agconnect/cloud';

interface RouteParams {
  record: WorkoutRecord;
}

@Entry
@Component
struct RecordDetailPage {
  @State private snapshotUrl: string | null = null;
  @State private isLoading: boolean = false;
  private record: WorkoutRecord = (router.getParams() as RouteParams).record;
  private storage: Storage = cloud.storage();

  aboutToAppear() {
    if (this.record.snapshotUrl) {
      this.loadSnapshotImage();
    }
  }

  async loadSnapshotImage() {
    this.isLoading = true;
    try {
      this.snapshotUrl = await this.storage.getDownloadURL(this.record.snapshotUrl);
    } catch (error) {
      console.error('Failed to get snapshot url:', error);
    } finally {
      this.isLoading = false;
    }
  }

  formatTime(seconds: number): string {
    const hours = Math.floor(seconds / 3600);
    const minutes = Math.floor((seconds % 3600) / 60);
    const secs = seconds % 60;
    return `${hours.toString().padStart(2, '0')}:${minutes.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}`;
  }

  formatDate(date: Date): string {
    const d = new Date(date);
    const year = d.getFullYear();
    const month = (d.getMonth() + 1).toString().padStart(2, '0');
    const day = d.getDate().toString().padStart(2, '0');
    const hours = d.getHours().toString().padStart(2, '0');
    const minutes = d.getMinutes().toString().padStart(2, '0');
    return `${year}年${month}月${day}日 ${hours}:${minutes}`;
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
  LoadingView() {
    Column() {
      LoadingProgress()
        .width(64)
        .height(64)
        .color('#007DFF')
      Text('加载中...')
        .fontSize(16)
        .fontColor('#666666')
        .margin({ top: 12 })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }

  @Builder
  IconText(icon: Resource, label: string, value: string, unit: string) {
    Column() {
      Text(label)
        .fontSize(14)
        .fontColor('#666666')
        .margin({ bottom: 4 })
      Row() {
        Image(icon)
          .width(24)
          .height(24)
          .margin({ right: 8 })
          .objectFit(ImageFit.Contain)
        Text(value)
          .fontSize(32)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')
      }
      Text(unit)
        .fontSize(14)
        .fontColor('#666666')
        .margin({ top: 4 })
    }
  }

  build() {
    Column() {
      // 标题栏保持不变
      Row() {
        Image($r('app.media.ic_back'))
          .width(24)
          .height(24)
          .onClick(() => router.back())
        Text('运动详情')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .margin({ left: 16 })
      }
      .width('100%')
      .height(56)
      .padding({ left: 16, right: 16 })
      .backgroundColor(Color.White)
      .shadow({
        radius: 12,
        color: '#0A000000',
        offsetY: 2
      })

      Column() {
        Column() {
          // 运动快照部分保持不变
          Stack() {
            if (this.record.snapshotUrl) {
              if (this.isLoading) {
                this.LoadingView()
              } else if (this.snapshotUrl) {
                Image(this.snapshotUrl)
                  .width('100%')
                  .height(240)
                  .objectFit(ImageFit.Cover)
                  .borderRadius(16)
                  .animation({
                    duration: 300,
                    curve: Curve.EaseOut
                  })
              }
            } else {
              Column() {
                Image($r('app.media.ic_no_image'))
                  .width(64)
                  .height(64)
                  .opacity(0.5)
                Text('暂无运动快照')
                  .fontSize(16)
                  .fontColor('#999999')
                  .margin({ top: 12 })
              }
              .width('100%')
              .height(240)
              .backgroundColor('#F5F5F5')
              .justifyContent(FlexAlign.Center)
              .borderRadius(16)
            }
          }
          .margin({ top: 16, left: 16, right: 16 })
          .borderRadius(16)
          .shadow({
            radius: 8,
            color: '#1A000000',
            offsetX: 2,
            offsetY: 4
          })

          // 运动类型和时间部分
          Column() {
            Row() {
              Image(this.getWorkoutTypeIcon(this.record.workoutType))
                .width(32)
                .height(32)
                .margin({ right: 12 })
              Text(this.record.workoutType)
                .fontSize(24)
                .fontWeight(FontWeight.Bold)
                .fontColor('#333333')
            }
            Text(this.formatDate(this.record.createTime))
              .fontSize(14)
              .fontColor('#666666')
              .margin({ top: 12 })
          }
          .width('100%')
          .alignItems(HorizontalAlign.Start)
          .padding({ left: 20, right: 20, top: 28, bottom: 20 })
          .margin({ top: 5 })

          // 运动数据展示区域
          Column() {
            Row() {
              Image($r('app.media.ic_timer'))
                .width(28)
                .height(28)
                .margin({ right: 8 })
              Text(this.formatTime(this.record.totalTime))
                .fontSize(48)
                .fontWeight(FontWeight.Bold)
                .fontColor('#333333')
            }
            .margin({ top: 8, bottom: 24 })

            Row() {
              Column() {
                this.IconText(
                  $r('app.media.ic_distance'),
                  '总距离',
                  `${this.record.totalDistance.toFixed(2)}`,
                  '公里'
                )
              }
              .layoutWeight(1)

              Divider()
                .vertical(true)
                .height(80)
                .color('#EEEEEE')
                .strokeWidth(1)

              Column() {
                this.IconText(
                  $r('app.media.ic_speed'),
                  '平均配速',
                  `${this.record.averageSpeed.toFixed(1)}`,
                  '公里/小时'
                )
              }
              .layoutWeight(1)
            }
            .width('100%')
            .padding({ left: 16, right: 16 })
          }
          .cardStyle()
          .margin({ bottom: 24 })
        }
      }
      .layoutWeight(1)
      .backgroundColor('#F5F5F5')
    }
    .width('100%')
    .height('100%')
  }

  // 获取运动类型对应的图标
  private getWorkoutTypeIcon(workoutType: string): Resource {
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
}