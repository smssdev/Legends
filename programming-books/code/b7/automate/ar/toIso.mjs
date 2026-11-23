function toIso(text) {
    // تحقق من أن النص يحتوي على تاريخ
    const dateRegex = /(\d{1,2})[\/\-\.](\d{1,2})[\/\-\.](\d{4})/;
    const dateMatch = text.match(dateRegex);
    
    if (!dateMatch) {
        // إذا لم يُوجد تطابق، نحاول التعرف على التواريخ باللغة العربية
        const arabicDateRegex = /(\d+)\s+(الينا|يناير|فبراير|مارس|أبريل|مايو|يونيو|يوليو|أغسطس|سبتمبر|أكتوبر|نوفمبر|ديسمبر)/;
        const arabicMatch = text.match(arabicDateRegex);
        
        if (arabicMatch) {
            const day = arabicMatch[1];
            const monthName = arabicMatch[2];
            const monthMap = {
                "يناير": "01",
                "فبراير": "02",
                "مارس": "03",
                "أبريل": "04",
                "مايو": "05",
                "يونيو": "06",
                "يوليو": "07",
                "أغسطس": "08",
                "سبتمبر": "09",
                "أكتوبر": "10",
                "نوفمبر": "11",
                "ديسمبر": "12"
            };
            const month = monthMap[monthName];
            return `${text.match(/(\d{4})/)[1]}-${month}-${day.padStart(2, '0')}`;
        }
        return null;
    }

    const day = dateMatch[1];
    const month = dateMatch[2];
    const year = dateMatch[3];

    // تأكد من أن الرقمين للشهر واليوم مُستوفى
    const formattedDay = day.padStart(2, '0');
    const formattedMonth = month.padStart(2, '0');
    
    return `${year}-${formattedMonth}-${formattedDay}`;
}

export {toIso};
