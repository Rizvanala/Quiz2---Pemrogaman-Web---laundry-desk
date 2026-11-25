package laundry.desk;

public final class Outcome {

    public final boolean ok;
    public final String message;

    private Outcome(boolean ok, String message) {
        this.ok = ok;
        this.message = message;
    }

    public static Outcome good(String message) {
        return new Outcome(true, message);
    }

    public static Outcome bad(String message) {
        return new Outcome(false, message);
    }
}
