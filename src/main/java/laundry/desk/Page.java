package laundry.desk;

import java.util.List;
import java.util.Map;

public final class Page {

    private final List<Map<String, Object>> rows;
    private final int page;
    private final int pages;
    private final long total;

    public Page(List<Map<String, Object>> rows, int page, int pages, long total) {
        this.rows = rows;
        this.page = page;
        this.pages = pages;
        this.total = total;
    }

    public List<Map<String, Object>> getRows() {
        return rows;
    }

    public int getPage() {
        return page;
    }

    public int getPages() {
        return pages;
    }

    public long getTotal() {
        return total;
    }
}
