const functions = require("firebase-functions");
const admin = require("firebase-admin");
const { GoogleGenerativeAI } = require("@google/generative-ai");

admin.initializeApp();

// ملاحظة: يفضل استخدام environment variables بدلاً من كتابة المفتاح هنا مباشرة
// firebase functions:config:set gemini.key="YOUR_KEY"
const API_KEY = "YOUR_GEMINI_API_KEY";
const genAI = new GoogleGenerativeAI(API_KEY);

/**
 * وظيفة تراقب إضافة أي عرض جديد وتقوم بتحويل وصفه إلى Vector
 */
exports.generateOfferEmbedding = functions.firestore
    .document("deals/{dealId}") // تم تغييرها لـ deals لتناسب مشروعك
    .onCreate(async (snap, context) => {
        const data = snap.data();
        
        // نأخذ الوصف أو اسم المنتج لتحويله إلى Vector
        const textToEmbed = `${data.product || ""} ${data.description || ""} ${data.storeName || ""}`.trim();

        if (textToEmbed.length === 0) {
            console.log("No text to embed for document:", context.params.dealId);
            return null;
        }

        try {
            const model = genAI.getGenerativeModel({ model: "text-embedding-004" });
            const result = await model.embedContent(textToEmbed);
            const embedding = result.embedding.values;

            console.log(`Successfully generated embedding for deal: ${context.params.dealId}`);

            // تحديث المستند بإضافة حقل الـ embedding كـ VectorValue
            return snap.ref.update({
                embedding: admin.firestore.FieldValue.vector(embedding),
                lastUpdated: admin.firestore.FieldValue.serverTimestamp()
            });
        } catch (error) {
            console.error("Embedding Generation Error:", error);
            return null;
        }
    });
