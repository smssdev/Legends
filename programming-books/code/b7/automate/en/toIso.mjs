function toIso(text) {
    // Handle formats with day before month (e.g., 12/01/2026, 01.02.2026)
    const dayMonthYearRegex = /(\d{1,2})[\/\.\-](\d{1,2})[\/\.\-](\d{4})/;
    const monthDayYearRegex = /(\d{1,2})[\/\.\-](\d{1,2})[\/\.\-](\d{4})/;
    
    // Try to match day-month-year format (day comes before month)
    const match = text.match(dayMonthYearRegex);
    if (match) {
        const day = parseInt(match[1], 10);
        const month = parseInt(match[2], 10);
        const year = parseInt(match[3], 10);
        // Validate month and day
        if (month >= 1 && month <= 12 && day >= 1 && day <= 31) {
            return `${year}-${String(month).padStart(2, '0')}-${String(day).padStart(2, '0')}`;
        }
    }
    
    // Try to match month-day-year format (e.g., 2026-1-3)
    const match2 = text.match(/(\d{4})-(\d{1,2})-(\d{1,2})/);
    if (match2) {
        const year = parseInt(match2[1], 10);
        const month = parseInt(match2[2], 10);
        const day = parseInt(match2[3], 10);
        if (month >= 1 && month <= 12 && day >= 1 && day <= 31) {
            return `${year}-${String(month).padStart(2, '0')}-${String(day).padStart(2, '0')}`;
        }
    }
    
    // Try to match "day Month year" format (e.g., 3 Jan 2026)
    const dayMonthYearWordRegex = /(\d{1,2})\s+([A-Za-z]+)\s+(\d{4})/;
    const match3 = text.match(dayMonthYearWordRegex);
    if (match3) {
        const day = parseInt(match3[1], 10);
        const monthName = match3[2].toLowerCase();
        const year = parseInt(match3[3], 10);
        
        const monthMap = {
            'jan': 1, 'feb': 2, 'mar': 3, 'apr': 4, 'may': 5, 'jun': 6,
            'jul': 7, 'aug': 8, 'sep': 9, 'oct': 10, 'nov': 11, 'dec': 12
        };
        
        const month = monthMap[monthName];
        if (month && day >= 1 && day <= 31) {
            return `${year}-${String(month).padStart(2, '0')}-${String(day).padStart(2, '0')}`;
        }
    }
    
    // Try to match "Month day, year" format (e.g., January 15, 2026)
    const monthDayYearWordRegex = /([A-Za-z]+)\s+(\d{1,2}),\s+(\d{4})/;
    const match4 = text.match(monthDayYearWordRegex);
    if (match4) {
        const monthName = match4[1].toLowerCase();
        const day = parseInt(match4[2], 10);
        const year = parseInt(match4[3], 10);
        
        const monthMap = {
            'jan': 1, 'feb': 2, 'mar': 3, 'apr': 4, 'may': 5, 'jun': 6,
            'jul': 7, 'aug': 8, 'sep': 9, 'oct': 10, 'nov': 11, 'dec': 12
        };
        
        const month = monthMap[monthName];
        if (month && day >= 1 && day <= 31) {
            return `${year}-${String(month).padStart(2, '0')}-${String(day).padStart(2, '0')}`;
        }
    }
    
    // Default fallback (if no format matches)
    return null;
}

export {toIso};
