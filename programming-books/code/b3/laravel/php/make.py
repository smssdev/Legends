"""Writes the examples of Book 3 (Laravel edition), chapter 2 "Modern PHP for JavaScript Developers".
Run: python3 make.py   (PHP 8.5 runs in Docker through code/b3/bin/php; see code/b3/php/Dockerfile)

A small Composer project per language (<lang>/): classes for Bit's shop in src/ (autoloaded with PSR-4),
demos/ that compare PHP with JavaScript, and PHPStan. Every script is run for real, and what the
terminal showed is saved as the transcripts the chapter prints (*.sh).
"""
import shutil
import sys
from pathlib import Path

HERE = Path(__file__).parent
B3 = HERE.parent.parent
sys.path.insert(0, str(B3))
from rec import Session, fill  # noqa: E402

sys.path.insert(0, str(B3 / "php"))
from seed import seed  # noqa: E402

T = {
    "en": dict(
        w_kit="Robot kit", w_wheels="Spare wheels", w_battery="Battery pack", w_name="Sara",
        w_pending="Waiting for payment", w_paid="Paid, being packed", w_shipped="On its way", w_cancelled="Cancelled",
        w_hello="Hello", w_items="items", w_total="total", w_neg="An amount cannot be negative",
        w_mix="Cannot add {a} to {b}", w_qty="Quantity must be at least 1",
        w_c_promo="constructor promotion: the parameters are the properties",
        w_c_readonly="readonly: set once, in the constructor, never again",
        w_c_hook="a property hook: read like a property, computed like a method",
        w_c_set="anyone can read it; only the class can change it",
        w_c_never="never: this function always throws, it never returns",
        w_c_by_value="fn captures by value, automatically",
        w_c_use="function () needs use to capture, also by value",
        w_c_ref="&$count: by reference, the JavaScript way",
        w_c_strict="strict types: no silent conversions in this file",
        w_c_bug="a bug PHPStan finds without running anything",
        w_s_run="Run a script", w_s_types="Types and the strict mode",
        w_s_loose="Without declare(strict_types=1), PHP converts the string quietly",
        w_s_strict="With it, the same call is an error",
        w_s_eq="Loose and strict comparison", w_s_arr="Arrays: one type for lists and maps",
        w_s_fn="Functions and closures", w_s_cls="Classes, enums and errors",
        w_s_auto="Composer writes the autoloader for the classes in src/",
        w_s_stan="PHPStan checks the types without running the code",
        w_s_lint="php -l only checks the syntax",
    ),
    "ar": dict(
        w_kit="عدة الروبوت", w_wheels="عجلات احتياطية", w_battery="حزمة بطارية", w_name="سارة",
        w_pending="بانتظار الدفع", w_paid="مدفوع", w_shipped="في الطريق", w_cancelled="ملغى",
        w_hello="أهلاً", w_items="قطع", w_total="الإجمالي", w_neg="لا يجوز أن يكون المبلغ سالباً",
        w_mix="لا يمكن جمع {a} مع {b}", w_qty="يجب أن تكون الكمية 1 على الأقل",
        w_c_promo="ترقية المُنشئ: المعاملات هي الخصائص نفسها",
        w_c_readonly="readonly: تُضبط مرة واحدة في المُنشئ، ولا تتغير بعدها",
        w_c_hook="خطّاف خاصية: يُقرأ كخاصية، ويُحسب كدالة",
        w_c_set="يقرؤها الجميع، ولا يغيّرها إلا الصنف نفسه",
        w_c_never="never: هذه الدالة ترمي دائماً، ولا تعود أبداً",
        w_c_by_value="fn تلتقط بالقيمة تلقائياً",
        w_c_use="function () تحتاج use لتلتقط، وبالقيمة أيضاً",
        w_c_ref="&$count: بالمرجع، على طريقة JavaScript",
        w_c_strict="الأنواع الصارمة: لا تحويلات صامتة في هذا الملف",
        w_c_bug="خطأ يجده PHPStan دون تشغيل أي شيء",
        w_s_run="شغّل سكربتاً", w_s_types="الأنواع والوضع الصارم",
        w_s_loose="بدون declare(strict_types=1) تحوّل PHP النص بصمت",
        w_s_strict="ومعه يصير الاستدعاء نفسه خطأ",
        w_s_eq="المقارنة المرنة والصارمة", w_s_arr="المصفوفات: نوع واحد للقوائم والخرائط",
        w_s_fn="الدوال والدوال المغلقة", w_s_cls="الأصناف والتعدادات والأخطاء",
        w_s_auto="يكتب Composer المحمّل التلقائي لأصناف المجلد src/",
        w_s_stan="يفحص PHPStan الأنواع دون تشغيل الكود",
        w_s_lint="php -l لا يفحص إلا الصياغة",
    ),
}

# The comments written in English in FILES, for the Arabic edition.
COMMENTS_AR = {
    "minor units: piastres, halalas, cents": "بالوحدات الصغرى: قروش، هللات، سنتات",
    "PHP 8.5: clone with new values. Nothing changes: you get a changed copy.":
        "PHP 8.5: النسخ بقيم جديدة. لا شيء يتغير: تحصل على نسخة معدّلة.",
    "readonly properties can only be set from inside the class": "خصائص readonly لا تُضبط إلا من داخل الصنف",
    "too late: fn already copied 10": "متأخر جداً: نسخت fn القيمة 10 من قبل",
    "push": "إضافة إلى الآخر",
    "Destructuring, like JavaScript": "التفكيك، كما في JavaScript",
    "Named arguments: skip to the one you need, in any order": "المعاملات المسماة: انتقل إلى ما تحتاجه، بأي ترتيب",
    "One type, two uses: a list (keys 0, 1, 2...) and a map (keys you choose).":
        "نوع واحد واستخدامان: قائمة (مفاتيحها 0 و1 و2...) وخريطة (مفاتيح تختارها).",
    'PHP 8 compares a number and a non-numeric string as strings: 0 == "a" is false.':
        'PHP 8 تقارن العدد بالنص غير الرقمي كنصين: 0 == "a" خطأ.',
    "PHP 8.4: find, any, all": "PHP 8.4: البحث، وأيٌّ، وكلٌّ",
    "PHP 8.4: no parentheses needed around new before calling a method": "PHP 8.4: لا حاجة لأقواس حول new قبل استدعاء دالة",
    "PHP 8.5: the pipe operator passes the value on the left to the callable on the right":
        "PHP 8.5: عامل الأنبوب يمرر القيمة التي على يساره إلى الدالة التي على يمينه",
    "Unlike JavaScript, assigning an array copies it": "بخلاف JavaScript، إسناد المصفوفة ينسخها",
    "map, filter, reduce: careful, the order of the arguments differs": "map وfilter وreduce: انتبه، ترتيب المعاملات يختلف",
    "still 0: the closure changed its own copy": "ما زال 0: غيّرت الدالة المغلقة نسختها هي",
    "single quotes: no interpolation": "علامات التنصيص المفردة: لا استبدال للمتغيرات",
    "the keys are kept: 1 and 3, not 0 and 1": "تبقى المفاتيح: 1 و3، لا 0 و1",
    "a string from a form, converted quietly": "نص من نموذج، يُحوَّل بصمت",
    "even true becomes 1": "حتى true تصبح 1",
}

FILES = {
    "composer.json": '''{
    "name": "bit/shop",
    "description": "Bit's shop: the classes of chapter 2",
    "type": "project",
    "require": {
        "php": "^8.5"
    },
    "require-dev": {
        "phpstan/phpstan": "^2.1"
    },
    "autoload": {
        "psr-4": {
            "Shop\\\\": "src/"
        }
    }
}
''',
    "phpstan.neon": '''parameters:
    level: max
    paths:
        - src
        - demos/bug.php
''',
    "demos/hello.php": '''<?php

$name = '{w_name}';
$items = 3;
echo "{w_hello}, $name! {w_items}: {$items}\\n";
echo '{w_hello}, $name!' . "\\n"; // single quotes: no interpolation
''',
    "demos/loose.php": '''<?php

function total(int $price, int $quantity): int
{
    return $price * $quantity;
}

var_dump(total("45000", 2)); // a string from a form, converted quietly
var_dump(total(45000, true)); // even true becomes 1
''',
    "demos/strict.php": '''<?php

declare(strict_types=1); // {w_c_strict}

function total(int $price, int $quantity): int
{
    return $price * $quantity;
}

var_dump(total(45000, 2));
var_dump(total("45000", 2));
''',
    "demos/equality.php": '''<?php

// PHP 8 compares a number and a non-numeric string as strings: 0 == "a" is false.
$pairs = [[0, "a"], ["1", "01"], ["10", "1e1"], [100, "100"], [null, false], [[], false]];
foreach ($pairs as [$a, $b]) {
    printf("%-6s %-6s  ==  %-5s  ===  %s\\n",
        json_encode($a), json_encode($b), json_encode($a == $b), json_encode($a === $b));
}
''',
    "demos/arrays.php": '''<?php

declare(strict_types=1);

// One type, two uses: a list (keys 0, 1, 2...) and a map (keys you choose).
$prices = [45000, 6000, 12500];
$product = ['id' => 1, 'name' => '{w_kit}', 'price' => 45000];

$prices[] = 2500; // push
echo count($prices), ' ', $product['name'], ' ', $product['stock'] ?? 0, "\\n";

// Unlike JavaScript, assigning an array copies it
$copy = $prices;
$copy[] = 99;
echo count($prices), ' ', count($copy), "\\n";

// Destructuring, like JavaScript
[$first, $second] = $prices;
['name' => $name, 'price' => $price] = $product;
echo "$first $second $name $price\\n";

// map, filter, reduce: careful, the order of the arguments differs
$cheap = array_filter($prices, fn (int $p) => $p < 10000);
$doubled = array_map(fn (int $p) => $p * 2, $prices);
$sum = array_reduce($prices, fn (int $carry, int $p) => $carry + $p, 0);
print_r($cheap); // the keys are kept: 1 and 3, not 0 and 1
echo json_encode(array_values($cheap)), ' ', json_encode($doubled), " $sum\\n";

// PHP 8.4: find, any, all
$big = array_find($prices, fn (int $p) => $p > 10000);
$any = array_any($prices, fn (int $p) => $p > 40000);
$all = array_all($prices, fn (int $p) => $p > 0);
var_dump($big, $any, $all);

// PHP 8.5: the pipe operator passes the value on the left to the callable on the right
$label = '  {w_kit}  ' |> trim(...) |> mb_strtoupper(...) |> (fn (string $s) => "[$s]");
echo $label, "\\n";
''',
    "demos/closures.php": '''<?php

declare(strict_types=1);

$discount = 10;
// {w_c_by_value}
$apply = fn (int $price): int => $price - intdiv($price * $discount, 100);
$discount = 50; // too late: fn already copied 10
echo $apply(45000), "\\n";

$count = 0;
// {w_c_use}
$increment = function () use ($count): int {
    return ++$count;
};
$increment();
$increment();
echo $count, "\\n"; // still 0: the closure changed its own copy

// {w_c_ref}
$counter = function () use (&$count): void {
    $count++;
};
$counter();
$counter();
echo $count, "\\n";

// Named arguments: skip to the one you need, in any order
echo str_pad(string: '7', length: 3, pad_string: '0', pad_type: STR_PAD_LEFT), "\\n";
echo json_encode(['name' => '{w_kit}'], flags: JSON_UNESCAPED_UNICODE), "\\n";
''',
    "src/Currency.php": '''<?php

declare(strict_types=1);

namespace Shop;

enum Currency: string
{
    case EGP = 'EGP';
    case SAR = 'SAR';
    case USD = 'USD';

    public function symbol(): string
    {
        return match ($this) {
            self::EGP => 'E£',
            self::SAR => 'SR',
            self::USD => '$',
        };
    }
}
''',
    "src/Money.php": '''<?php

declare(strict_types=1);

namespace Shop;

use InvalidArgumentException;

// {w_c_readonly}
final readonly class Money
{
    // {w_c_promo}
    public function __construct(
        public int $amount, // minor units: piastres, halalas, cents
        public Currency $currency,
    ) {
        if ($amount < 0) {
            throw new InvalidArgumentException('{w_neg}');
        }
    }

    public function plus(Money $other): Money
    {
        if ($other->currency !== $this->currency) {
            throw new CurrencyMismatch($this->currency, $other->currency);
        }
        return new Money($this->amount + $other->amount, $this->currency);
    }

    public function times(int $quantity): Money
    {
        return new Money($this->amount * $quantity, $this->currency);
    }

    public function format(): string
    {
        $whole = intdiv($this->amount, 100);
        $cents = str_pad((string) ($this->amount % 100), 2, '0', STR_PAD_LEFT);
        return "{$this->currency->symbol()} " . number_format($whole) . ".$cents";
    }
}
''',
    "src/CurrencyMismatch.php": '''<?php

declare(strict_types=1);

namespace Shop;

use DomainException;

final class CurrencyMismatch extends DomainException
{
    public function __construct(
        public readonly Currency $left,
        public readonly Currency $right,
    ) {
        $message = strtr('{w_mix}', [
            '{a}' => $right->value,
            '{b}' => $left->value,
        ]);
        parent::__construct($message);
    }
}
''',
    "src/OrderStatus.php": '''<?php

declare(strict_types=1);

namespace Shop;

enum OrderStatus: string
{
    case Pending = 'pending';
    case Paid = 'paid';
    case Shipped = 'shipped';
    case Cancelled = 'cancelled';

    public function label(): string
    {
        return match ($this) {
            self::Pending => '{w_pending}',
            self::Paid => '{w_paid}',
            self::Shipped => '{w_shipped}',
            self::Cancelled => '{w_cancelled}',
        };
    }

    public function canCancel(): bool
    {
        return in_array($this, [self::Pending, self::Paid], true);
    }
}
''',
    "src/Product.php": '''<?php

declare(strict_types=1);

namespace Shop;

final readonly class Product
{
    public function __construct(
        public int $id,
        public string $name,
        public Money $price,
    ) {}

    // PHP 8.5: clone with new values. Nothing changes: you get a changed copy.
    public function onSale(int $percent): static
    {
        $amount = intdiv($this->price->amount * (100 - $percent), 100);
        return clone($this, [
            'name' => "{$this->name} (-{$percent}%)",
            'price' => new Money($amount, $this->price->currency),
        ]);
    }
}
''',
    "src/Cart.php": '''<?php

declare(strict_types=1);

namespace Shop;

use InvalidArgumentException;

final class Cart
{
    // {w_c_set}
    /** @var array<int, array{product: Product, quantity: int}> */
    public private(set) array $lines = [];

    // {w_c_hook}
    public Money $total {
        get => array_reduce(
            $this->lines,
            fn (Money $sum, array $line) => $sum->plus(
                $line['product']->price->times($line['quantity']),
            ),
            new Money(0, $this->currency),
        );
    }

    public int $count {
        get => array_sum(array_column($this->lines, 'quantity'));
    }

    public function __construct(public readonly Currency $currency) {}

    public function add(Product $product, int $quantity = 1): static
    {
        if ($quantity < 1) {
            throw new InvalidArgumentException('{w_qty}');
        }
        $current = $this->lines[$product->id]['quantity'] ?? 0;
        $this->lines[$product->id] = [
            'product' => $product,
            'quantity' => $current + $quantity,
        ];
        return $this;
    }
}
''',
    "demos/shop.php": '''<?php

declare(strict_types=1);

require __DIR__ . '/../vendor/autoload.php';

use Shop\\{Cart, Currency, CurrencyMismatch, Money, OrderStatus, Product};

$kit = new Product(1, '{w_kit}', new Money(45000, Currency::EGP));
$wheels = new Product(2, '{w_wheels}', new Money(6000, Currency::EGP));

// PHP 8.4: no parentheses needed around new before calling a method
$cart = new Cart(Currency::EGP)->add($kit)->add($wheels, 2);
echo "{$cart->count} {w_items}, {w_total}: {$cart->total->format()}\\n";

$status = OrderStatus::from('paid');
echo $status->name, ' / ', $status->label(), ' / ', json_encode($status->canCancel()), "\\n";
var_dump(OrderStatus::tryFrom('lost'));
echo implode(', ', array_map(fn (OrderStatus $s) => $s->value, OrderStatus::cases())), "\\n";

try {
    $kit->price->plus(new Money(100, Currency::USD));
} catch (CurrencyMismatch $e) {
    echo get_class($e), ': ', $e->getMessage(), "\\n";
}

try {
    $cart->lines = [];
} catch (Error $e) {
    echo get_class($e), ': ', $e->getMessage(), "\\n";
}

try {
    $kit->price->amount = 1;
} catch (Error $e) {
    echo get_class($e), ': ', $e->getMessage(), "\\n";
}

try {
    // readonly properties can only be set from inside the class
    clone($kit, ['name' => 'X']);
} catch (Error $e) {
    echo get_class($e), ': ', $e->getMessage(), "\\n";
}

$sale = $kit->onSale(10);
echo $sale->name, ' ', $sale->price->format(), ' / ', $kit->price->format(), "\\n";
''',
    "demos/bug.php": '''<?php

declare(strict_types=1);

use Shop\\{Currency, Money, OrderStatus};

// {w_c_bug}
function refund(Money $paid, ?OrderStatus $status): Money
{
    if ($status->canCancel()) {
        return $paid;
    }
    return new Money('0', Currency::EGP);
}
''',
    "answers/equality.php": """<?php

foreach ([['abc', 0], ['1', '1.0'], [null, 0], ['', null], ['0', false], [' 1', 1]] as [$a, $b]) {
    printf("%-6s == %-5s  %s\n", json_encode($a), json_encode($b), json_encode($a == $b));
}
""",
    "answers/walk.php": """<?php

declare(strict_types=1);

$prices = [45000, 6000, 12500];
$total = 0;
array_walk($prices, function (int $p) use ($total): void {
    $total += $p;
});
echo $total, "\n"; // 0: the closure added to its own copy

array_walk($prices, function (int $p) use (&$total): void {
    $total += $p;
});
echo $total, ' ', array_sum($prices), "\n";
""",
    "answers/src/Currency.php": """<?php

declare(strict_types=1);

namespace Shop;

enum Currency: string
{
    case EGP = 'EGP';
    case SAR = 'SAR';
    case USD = 'USD';
    case KWD = 'KWD';

    public function symbol(): string
    {
        return match ($this) {
            self::EGP => 'E£',
            self::SAR => 'SR',
            self::USD => '$',
            self::KWD => 'KD',
        };
    }

    // Minor units in one major unit: 100 piastres in a pound, 1000 fils in a Kuwaiti dinar.
    public function decimals(): int
    {
        return match ($this) {
            self::KWD => 3,
            default => 2,
        };
    }
}
""",
    "answers/run.php": """<?php

declare(strict_types=1);

// The answers' versions of the classes are loaded first; everything else comes from src/.
spl_autoload_register(function (string $class): void {
    $name = substr($class, strlen('Shop\\\\')) . '.php';
    foreach ([__DIR__ . '/src/', __DIR__ . '/../src/'] as $dir) {
        if (is_file($dir . $name)) {
            require $dir . $name;
            return;
        }
    }
});

use Shop\\{Cart, Currency, Money, Product};

echo new Money(123456, Currency::KWD)->format(), ' ', new Money(123456, Currency::EGP)->format(), "\n";

$cart = new Cart(Currency::EGP)->add(new Product(1, 'Kit', new Money(45000, Currency::EGP)), 2);
$cart->discountPercent = 10;
echo $cart->total->format(), ' -> ', $cart->payable->format(), "\n";
try {
    $cart->discountPercent = 150;
} catch (ValueError $e) {
    echo get_class($e), ': ', $e->getMessage(), "\n";
}
echo $cart->discountPercent, "\n";
""",
}

ANSWER_MONEY_FORMAT = (
    """        $whole = intdiv($this->amount, 100);
        $cents = str_pad((string) ($this->amount % 100), 2, '0', STR_PAD_LEFT);
        return "{$this->currency->symbol()} " . number_format($whole) . ".$cents";""",
    """        $decimals = $this->currency->decimals();
        $unit = 10 ** $decimals;
        $minor = str_pad((string) ($this->amount % $unit), $decimals, '0', STR_PAD_LEFT);
        return "{$this->currency->symbol()} " . number_format(intdiv($this->amount, $unit)) . ".$minor";""")

ANSWER_CART = (
    """    public int $count {""",
    """    public int $discountPercent = 0 {
        set(int $value) {
            if ($value < 0 || $value > 100) {
                throw new \\ValueError('discountPercent must be from 0 to 100');
            }
            $this->discountPercent = $value;
        }
    }

    public int $count {""")
ANSWER_TOTAL = (
    """            new Money(0, $this->currency),
        );
    }""",
    """            new Money(0, $this->currency),
        );
    }

    public Money $payable {
        get => new Money(intdiv($this->total->amount * (100 - $this->discountPercent), 100), $this->currency);
    }""")


def answers(folder):
    src = folder / "src"
    out = folder / "answers" / "src"
    money = (src / "Money.php").read_text()
    assert ANSWER_MONEY_FORMAT[0] in money
    (out / "Money.php").write_text(money.replace(*ANSWER_MONEY_FORMAT))
    cart = (src / "Cart.php").read_text()
    for old, new in (ANSWER_CART, ANSWER_TOTAL):
        assert old in cart, old
        cart = cart.replace(old, new)
    (out / "Cart.php").write_text(cart)


def record(folder, t):
    s = Session(folder)
    s.note(t["w_s_run"])
    s.run("php demos/hello.php")
    s.save(folder / "hello.sh")

    s.note(t["w_s_loose"])
    s.run("php demos/loose.php")
    s.note(t["w_s_strict"])
    s.run("php demos/strict.php 2>&1 | head -n 3", check=False)
    s.save(folder / "strict.sh")

    s.run("php demos/equality.php")
    s.save(folder / "equality.sh")

    s.run("php demos/arrays.php")
    s.save(folder / "arrays.sh")

    s.run("php demos/closures.php")
    s.save(folder / "closures.sh")

    s.note(t["w_s_auto"])
    s.run("composer install --quiet && composer dump-autoload")
    s.save(folder / "autoload.sh")

    s.run("php demos/shop.php")
    s.save(folder / "shop.sh")

    s.note(t["w_s_lint"])
    s.run("php -l demos/bug.php")
    s.note(t["w_s_stan"])
    s.run("vendor/bin/phpstan analyse --no-progress --error-format=raw", check=False)
    s.save(folder / "phpstan.sh")


seed("phpstan/phpstan", "2.3.7")  # see php/seed.py: only matters where GitHub's zip files are blocked
for lang, t in T.items():
    folder = HERE / lang
    if folder.exists():
        shutil.rmtree(folder)
    for name, text in FILES.items():
        path = folder / name
        path.parent.mkdir(parents=True, exist_ok=True)
        text = fill(text, t)
        if lang == "ar":
            for en, ar in COMMENTS_AR.items():
                text = text.replace(f"// {en}", f"// {ar}")
        path.write_text(text)
    record(folder, t)
    answers(folder)
    s = Session(folder)
    for script in ("equality", "walk", "run"):
        s.run(f"php answers/{script}.php")
    s.save(folder / "answers.sh")
    shutil.rmtree(folder / "vendor")
    print("wrote", lang)
