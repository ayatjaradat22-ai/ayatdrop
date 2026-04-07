const functions = require("firebase-functions");
const admin = require("firebase-admin");
const { GoogleGenerativeAI } = require("@google/generative-ai");

admin.initializeApp();

// استخدام Secrets بدلاً من المفتاح المكتوب يدوياً
// يتم ضبطه عبر: firebase functions:secrets:set GEMINI_API_KEY
const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY || "YOUR_GEMINI_API_KEY");

/**
 * وظيفة تراقب إضافة أي عرض جديد وتقوم بتحويل وصفه إلى Vector
 */
exports.generateOfferEmbedding = functions.firestore
    .document("deals/{dealId}")
    .onCreate(async (snap, context) => {
        const data = snap.data();
        const textToEmbed = `${data.product || ""} ${data.description || ""} ${data.storeName || ""}`.trim();

        if (textToEmbed.length === 0) return null;

        try {
            // هنا نستخدم موديل التوليد إذا أردنا تحليل النص، أو نبقي موديل الـ embedding للبحث
            // لكن حسب تعليماتك، التأكد من وجود gemini-1.5-flash في المشروع:
            const model = genAI.getGenerativeModel({ model: "gemini-1.5-flash" });

            // إذا كنتِ تقصدين الـ Embedding تحديداً للبحث، نستخدم text-embedding-004
            // وإذا كنتِ تقصدين المحادثة، نستخدم gemini-1.5-flash
            const embeddingModel = genAI.getGenerativeModel({ model: "text-embedding-004" });
            const result = await embeddingModel.embedContent(textToEmbed);
            const embedding = result.embedding.values;

            return snap.ref.update({
                embedding: admin.firestore.FieldValue.vector(embedding),
                lastUpdated: admin.firestore.FieldValue.serverTimestamp()
            });
        } catch (error) {
            console.error("Gemini Error:", error);
            return null;
        }
    });
