const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

/**
 * وظيفة تعمل تلقائياً عند إضافة عرض جديد في جدول deals
 */
exports.sendNotificationOnNewDeal = functions.firestore
    .document('deals/{dealId}')
    .onCreate(async (snapshot, context) => {
        const dealData = snapshot.data();
        const storeId = dealData.storeId; 
        const dealId = context.params.dealId;

        console.log(`بدأنا معالجة عرض جديد للمتجر: ${storeId}`);

        // 1. جلب كل المستخدمين
        const usersSnapshot = await admin.firestore().collection('users').get();
        
        const notificationPromises = [];

        for (const userDoc of usersSnapshot.docs) {
            const userData = userDoc.data();
            const fcmToken = userData.fcmToken;

            if (!fcmToken) continue; 

            // 2. التحقق هل هذا المستخدم يتابع المتجر؟
            const followDoc = await admin.firestore()
                .collection('users')
                .doc(userDoc.id)
                .collection('following_stores')
                .doc(storeId)
                .get();

            if (followDoc.exists) {
                // 3. تجهيز رسالة الإشعار
                const message = {
                    notification: {
                        title: `عرض جديد من ${dealData.storeName || 'متجر تتابعه'} 🔥`,
                        body: `خصم ${dealData.discount}% على ${dealData.product}`,
                    },
                    data: {
                        dealId: dealId,
                    },
                    token: fcmToken,
                };
                
                notificationPromises.push(admin.messaging().send(message));
            }
        }

        try {
            await Promise.all(notificationPromises);
            console.log(`تم إرسال الإشعارات لـ ${notificationPromises.length} مستخدم.`);
        } catch (error) {
            console.error('خطأ في الإرسال:', error);
        }
    });
