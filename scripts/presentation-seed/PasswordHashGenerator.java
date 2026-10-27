import com.uniconnect.shared.security.PasswordConfig;

public final class PasswordHashGenerator {
    private PasswordHashGenerator() {}

    public static void main(String[] args) {
        if (args.length != 1) throw new IllegalArgumentException("Expected exactly one password argument");
        System.out.print(new PasswordConfig().passwordEncoder().encode(args[0]));
    }
}
