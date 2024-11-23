// cloud/functions/get-user-info/index.js
import { cloud, CloudDBCollection } from '@hw-agconnect/cloud-server';//引入Server SDK依赖
import { UserInfo } from './UserInfo'; //BookInfo为对象类型名

// ZONE_NAME为存储区名称
const ZONE_NAME = "default";

let myHandler = async function (event, context, callback, logger) {
  try {
    const collection: CloudDBCollection<UserInfo> = cloud.database({ zoneName: ZONE_NAME }).collection(UserInfo);
    const { phoneNumber, uid } = JSON.parse(event.body) // 这里有点坑，params传入的参数在event.body中，需要手动解析

    // 查询用户信息
    const userResult = await collection.query()
      .equalTo("uid", uid)
      .get();

    if (userResult.length > 0) {
      // 用户存在，返回用户信息
      callback({
        code: 0,
        message: 'Success',
        data: userResult[0]
      });
    } else {
      // 用户不存在，创建新用户记录
      const newUser = {
        uid: uid,
        phoneNumber: phoneNumber,
        nickname: `用户${uid.substring(0, 6)}`,
        createTime: new Date(),
        updateTime: new Date(),
      };

      await collection.insert(newUser);

      callback({
        code: 0,
        message: 'User created',
        data: newUser
      });
    }
  } catch (error) {
    console.error('Error in getUserInfo:', error);
    callback({
      code: -1,
      message: error.message,
      data: null
    });
  }
};

export {myHandler}