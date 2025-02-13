const functions = require("firebase-functions/v2");
const admin = require("firebase-admin");
admin.initializeApp();

exports.sendNewTransferNotification = functions.firestore.onDocumentCreated(
    "transactions/{docId}",
    (event) => {
      const newValue = event.data;
      if (newValue.status === "تحويل جديد") {
        const payload = {
          notification: {
            title: "طلب تحويل",
            body: "طلب تحويل جديد " +
                  "في النظام",
            click_action: "https://alkawasir.online",
          },
        };

        return admin.messaging()
            .sendToTopic("allUsers", payload)
            .then((response) => {
              console.log("Notification sent successfully:", response);
            })
            .catch((error) => {
              console.error("Error sending notification:", error);
            });
      }
      return null;
    });

exports.sendNewAdReviewNotification = functions.firestore.onDocumentCreated(
    "created ads/{docId}",
    (event) => {
      const newValue = event.data;
      if (newValue.status === "في المراجعة") {
        const payload = {
          notification: {
            title: "إعلان جديد",
            body: "إعلان جديد للمراجعة",
            click_action: "https://alkawasir.online",
          },
        };

        return admin.messaging()
            .sendToTopic("allUsers", payload)
            .then((response) => {
              console.log("Notification sent successfully:", response);
            })
            .catch((error) => {
              console.error("Error sending notification:", error);
            });
      }
      return null;
    });

exports.sendNewCustomerRequestNotification = functions.firestore.onDocumentCreated(
    "customer requests/{docId}",
    (event) => {
      const newValue = event.data;
      const customerActions = [
        "طلب جديد",
        "تعديل اخر",
        "طلب إيقاف الإعلان",
        "طلب تعديل الاستهداف",
        "تزويد الإعلان",
        "تشغيل الإعلان",
        "استكمال الإعلان",
      ];

      if (customerActions.includes(newValue.action)) {
        const payload = {
          notification: {
            title: "طلب عميل جديد!",
            body: "طلب جديد",
            click_action: "https://alkawasir.online",
          },
        };

        return admin.messaging()
            .sendToTopic("allUsers", payload)
            .then((response) => {
              console.log("Notification sent successfully:", response);
            })
            .catch((error) => {
              console.error("Error sending notification:", error);
            });
      }
      return null;
    });
