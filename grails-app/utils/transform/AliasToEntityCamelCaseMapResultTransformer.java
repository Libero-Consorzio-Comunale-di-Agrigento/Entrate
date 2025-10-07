package transform;

import org.hibernate.transform.BasicTransformerAdapter;

import java.io.Serializable;
import java.util.HashMap;
import java.util.Locale;
import java.util.Map;

public class AliasToEntityCamelCaseMapResultTransformer extends BasicTransformerAdapter implements Serializable {
    public static final AliasToEntityCamelCaseMapResultTransformer INSTANCE = new AliasToEntityCamelCaseMapResultTransformer();

    private AliasToEntityCamelCaseMapResultTransformer() {
    }

    public Object transformTuple(Object[] tuple, String[] aliases) {
        Map<String, Object> result = new HashMap<String, Object>(tuple.length);

        for (int i = 0; i < tuple.length; ++i) {
            String alias = toCamelCase(aliases[i]);
            if (alias != null) {
                result.put(alias, tuple[i]);
            }
        }

        return result;
    }

    public static String toCamelCase(final String text) {

        String input = text;

        if (input.startsWith("_")) {
            input = input.substring(1);
        }
        if (input.endsWith("_")) {
            input = input.substring(0, input.length() - 1);
        }

        StringBuilder sb = new StringBuilder(input.toLowerCase(Locale.ROOT));

        for (int i = 0; i < sb.length(); i++) {
            if (sb.charAt(i) == '_') {
                sb.deleteCharAt(i);
                sb.replace(i, i + 1, String.valueOf(Character.toUpperCase(sb.charAt(i))));
            }
        }

        return sb.toString();
    }

    private Object readResolve() {
        return INSTANCE;
    }
}
