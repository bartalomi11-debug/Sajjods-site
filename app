

const ADMIN_SETTINGS = JSON.parse(
    localStorage.getItem("admin_settings") || "{}"
);

const EXAM_TIME =
    Number(ADMIN_SETTINGS.duration) || CONFIG.durationMinutes;

const EXAM_MAX_EXITS =
    Number(ADMIN_SETTINGS.maxExits ?? CONFIG.maxExits);

const EXAM_TITLE =
    ADMIN_SETTINGS.title || CONFIG.title;


/* =========================
   کلید پاسخ‌های 100 سؤال
   ========================= */

const ANSWERS = {
    1: 4,
    2: 4,
    3: 1,
    4: 2,
    5: 1,
    6: 2,
    7: 3,
    8: 4,
    9: 3,
    10: 1,

    11: 2,
    12: 3,
    13: 1,
    14: 4,
    15: 2,
    16: 1,
    17: 3,
    18: 1,
    19: 2,
    20: 3,

    21: 2,
    22: 4,
    23: 3,
    24: 2,
    25: 1,
    26: 1,
    27: 4,
    28: 3,
    29: 4,
    30: 1,

    31: 2,
    32: 1,
    33: 2,
    34: 3,
    35: 2,
    36: 4,
    37: 1,
    38: 2,
    39: 1,
    40: 2,

    41: 3,
    42: 4,
    43: 1,
    44: 2,
    45: 1,
    46: 2,
    47: 1,
    48: 4,
    49: 1,
    50: 3,

    51: 3,
    52: 2,
    53: 4,
    54: 1,
    55: 2,
    56: 3,
    57: 4,
    58: 1,
    59: 2,
    60: 2,

    61: 3,
    62: 4,
    63: 2,
    64: 1,
    65: 4,
    66: 3,
    67: 2,
    68: 1,
    69: 4,
    70: 2,

    71: 1,
    72: 4,
    73: 2,
    74: 3,
    75: 4,
    76: 3,
    77: 1,
    78: 4,
    79: 2,
    80: 2,

    81: 3,
    82: 4,
    83: 2,
    84: 1,
    85: 3,
    86: 4,
    87: 1,
    88: 2,
    89: 4,
    90: 3,

    91: 1,
    92: 3,
    93: 2,
    94: 4,
    95: 1,
    96: 1,
    97: 3,
    98: 3,
    99: 2,
    100: 3
};


/* =========================
   متغیرهای آزمون
   ========================= */

let i = 0;

let answers = {};

let seconds = EXAM_TIME * 60;

let exits = 0;

let started = false;

let finished = false;

let timer = null;

let candidate = null;

let startTime = null;


/* =========================
   انتخاب عناصر HTML
   ========================= */

const $ = id => document.getElementById(id);


/* =========================
   نمایش اطلاعات آزمون
   ========================= */

if ($("title")) {

    $("title").textContent = EXAM_TITLE;

}

if ($("info")) {

    $("info").textContent =
        `${QUESTIONS.length} سؤال | ${EXAM_TIME} دقیقه | حداکثر ${EXAM_MAX_EXITS} خروج`;

}


/* =========================
   دریافت داوطلب‌ها
   ========================= */

function getCandidates() {

    return JSON.parse(
        localStorage.getItem("candidates") || "[]"
    );

}


/* =========================
   بررسی نام و کد داوطلب
   ========================= */

function findCandidate(name, code) {

    const candidates = getCandidates();

    return candidates.find(candidate =>

        candidate.name.trim() === name.trim() &&

        candidate.code.trim() === code.trim()

    );

}


/* =========================
   محاسبه نمره
   ========================= */

function calculateScore(userAnswers) {

    let correct = 0;

    let wrong = 0;

    let unanswered = 0;


    for (
        let questionNumber = 1;
        questionNumber <= QUESTIONS.length;
        questionNumber++
    ) {

        const correctAnswer =
            ANSWERS[questionNumber];

        const selectedAnswer =
            userAnswers[questionNumber];


        /*
         اگر پاسخنامه‌ای برای سؤال وجود نداشته باشد،
         آن سؤال بدون پاسخ محسوب می‌شود.
        */

        if (correctAnswer === undefined) {

            unanswered++;

        }

        /*
         داوطلب سؤال را جواب نداده است.
        */

        else if (selectedAnswer === undefined) {

            unanswered++;

        }

        /*
         گزینه‌های سایت از 0 شروع می‌شوند
         ولی کلید پاسخ‌ها از 1 تا 4 است.
        */

        else if (
            selectedAnswer === correctAnswer - 1
        ) {

            correct++;

        }

        /*
         پاسخ داده ولی اشتباه است.
        */

        else {

            wrong++;

        }

    }


    /*
     درصد از کل 100 سؤال
    */

    const percent =
        QUESTIONS.length > 0
            ? (correct / QUESTIONS.length) * 100
            : 0;


    return {

        correct: correct,

        wrong: wrong,

        unanswered: unanswered,

        percent: Number(
            percent.toFixed(2)
        )

    };

}


/* =========================
   نمایش زمان
   ========================= */

function tm() {

    const min =
        Math.floor(seconds / 60);

    const sec =
        seconds % 60;


    return (

        String(min).padStart(2, "0") +

        ":" +

        String(sec).padStart(2, "0")

    );

}


/* =========================
   جلوگیری از HTML مخرب
   ========================= */

function esc(value) {

    return String(value).replace(
        /[&<>"']/g,

        character => ({

            "&": "&amp;",

            "<": "&lt;",

            ">": "&gt;",

            '"': "&quot;",

            "'": "&#039;"

        }[character])

    );

}


/* =========================
   شروع کون دادنب
   ========================= */

function startExam() {

    const name =
        $("name").value.trim();

    const code =
        $("code").value.trim();


    if (!name || !code) {

        alert(
            "لطفاً اسم و کدت وارد کن کونی."
        );

        return;

    }


    const found =
        findCandidate(name, code);


    if (!found) {

        alert(
            "اسم قشنگ یا کد عنت درست نیست گمشو درست بزن عنونه."
        );

        return;

    }


// جلوگیری از شرکت مجدد داوطلب
const examResults = JSON.parse(
    localStorage.getItem("exam_results") || "[]"
);

const alreadyParticipated = examResults.some(
    result => result.candidateCode === code
);

if (alreadyParticipated) {

    alert(
        "دادا یبار زدی دیجه."
    );

    return;
}

    candidate = found;

    startTime =
        new Date().toISOString();


    started = true;

    finished = false;

    i = 0;

    answers = {};

    exits = 0;

    seconds = EXAM_TIME * 60;


    $("start").classList.add("hidden");

    $("exam").classList.remove("hidden");


    $("timer").textContent =
        tm();


    draw();


    timer = setInterval(() => {

        seconds--;


        $("timer").textContent =
            tm();


        save();


        if (seconds <= 0) {

            finish(true);

        }

    }, 1000);


    save();

}


/* =========================
   نمایش سؤال
   ========================= */

function draw() {

    const q =
        QUESTIONS[i];


    $("meta").textContent =

        `کونب: ${
            candidate ? candidate.name : ""
        } | سؤال ${
            i + 1
        } از ${
            QUESTIONS.length
        } | پاسخ داده‌شده: ${
            Object.keys(answers).length
        }`;


    $("question").innerHTML =

        '<div class="q">' +

        esc(q.text) +

        '</div>';


    $("options").innerHTML =

        q.options.map(
            (option, index) => `

            <label class="option ${
                answers[q.id] === index
                    ? "selected"
                    : ""
            }">

                <input
                    type="radio"
                    name="o"

                    ${
                        answers[q.id] === index
                            ? "checked"
                            : ""
                    }

                    onchange="pick(${index})"
                >

                ${index + 1})
                ${esc(option)}

            </label>

        `
        ).join("");


    $("nav").innerHTML =

        '<div class="nav">' +

        QUESTIONS.map(
            (question, index) => `

            <button

                class="${
                    index === i
                        ? "cur "
                        : ""
                }${
                    answers[question.id] !== undefined
                        ? "ans"
                        : ""
                }"

                onclick="go(${index})"

            >

                ${index + 1}

            </button>

        `
        ).join("") +

        '</div>';

}


/* =========================
   انتخاب گزینه
   ========================= */

function pick(index) {

    answers[
        QUESTIONS[i].id
    ] = index;


    save();


    draw();

}


/* =========================
   برو به سوالات
   ========================= */

function go(index) {

    i = index;

    draw();

}


/* =========================
   سوال قبلیت عن
   ========================= */

function prev() {

    if (i > 0) {

        i--;

        draw();

    }

}


/* =========================
   سوال بعدیت عن
   ========================= */

function next() {

    if (
        i < QUESTIONS.length - 1
    ) {

        i++;

        draw();

    }

    else {

        finish(false);

    }

}


/* =========================
   کون دادنت تمومه؟
   ========================= */

function save() {

    if (
        !started ||
        finished ||
        !candidate
    ) {

        return;

    }


    localStorage.setItem(

        "exam_state_" +
        candidate.code,

        JSON.stringify({

            i: i,

            answers: answers,

            seconds: seconds,

            exits: exits,

            candidate: candidate,

            startTime: startTime

        })

    );

}


/* =========================
   پایان چون دادنت بوج
   ========================= */

function finish(auto) {

    if (finished) {

        return;

    }


    if (
        !auto &&
        !confirm(
            "چون دادنت تمومه؟"
        )
    ) {

        return;

    }


    finished = true;


    clearInterval(timer);


    const endTime =
        new Date().toISOString();


    /*
     محاسبه نمره
    */

    const score =
        calculateScore(answers);


    /*
     ساخت نتیجه
    */

    const result = {

        candidateName:
            candidate.name,

        candidateCode:
            candidate.code,

        startTime:
            startTime,

        endTime:
            endTime,

        answered:
            Object.keys(answers).length,

        totalQuestions:
            QUESTIONS.length,

        correct:
            score.correct,

        wrong:
            score.wrong,

        unanswered:
            score.unanswered,

        percent:
            score.percent,

        exits:
            exits,

        answers:
            answers,

        autoFinished:
            auto

    };


    /*
     دریافت نتایج قبلی
    */

    const results =
        JSON.parse(
            localStorage.getItem(
                "exam_results"
            ) || "[]"
        );


    /*
     اضافه کردن نتیجه جدید
    */

    results.push(result);


    /*
     ذخیره نتیجه
    */

    localStorage.setItem(

        "exam_results",

        JSON.stringify(results)

    );


    /*
     پاک کردن وضعیت موقت کون دادن
    */

    localStorage.removeItem(

        "exam_state_" +
        candidate.code

    );


    /*
     نمایش نتیجه
    */

    $("exam").classList.add(
        "hidden"
    );

    $("result").classList.remove(
        "hidden"
    );


    $("summary").innerHTML = `

        <p>
            کونب:
            <strong>
                ${esc(candidate.name)}
            </strong>
        </p>


        <p>
            کد کونب:
            <strong>
                ${esc(candidate.code)}
            </strong>
        </p>


        <p>
            تعداد پاسخ داده‌شده:
            <strong>
                ${Object.keys(answers).length}
            </strong>
            از
            ${QUESTIONS.length}
        </p>


        <p>
            صحیح:
            <strong>
                ${score.correct}
            </strong>
        </p>


        <p>
            غلط:
            <strong>
                ${score.wrong}
            </strong>
        </p>


        <p>
            بدون پاسخ:
            <strong>
                ${score.unanswered}
            </strong>
        </p>


        <p>
            درصد:
            <strong>
                ${score.percent}%
            </strong>
        </p>


        <p>
            تعداد خروج:
            <strong>
                ${exits}
            </strong>
        </p>


        ${
            auto

            ? `
                <p>
                    <strong>
                        داوگ.
                    </strong>
                </p>
            `

            : ""
        }

    `;

}


/* =========================
   کنترل خروج از صفحه
   ========================= */

document.addEventListener(
    "visibilitychange",
    () => {

        if (
            !started ||
            finished
        ) {

            return;

        }


        if (
            document.hidden
        ) {

            document.body.dataset.left =
                "1";

        }


        else if (
            document.body.dataset.left === "1"
        ) {

            document.body.dataset.left =
                "0";


            exits++;


            save();


            alert(

                `خروج از صفحه ثبت شد: ${
                    exits
                } از ${
                    EXAM_MAX_EXITS
                }`

            );


            /*
             اگر تعداد خروج به حد مجاز رسید،
             آزمون تمام شود.
            */

            if (

                EXAM_MAX_EXITS > 0 &&

                exits >= EXAM_MAX_EXITS &&

                CONFIG.autoFinishOnMaxExits

            ) {

                finish(true);

            }

        }

    }
);


/* =========================
   ذخیره هنگام بستن صفحه
   ========================= */

window.addEventListener(
    "beforeunload",
    save
);
