import "jsr:@supabase/functions-js/edge-runtime.d.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "GET, POST, PUT, DELETE, OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type, Authorization, X-Client-Info, Apikey",
};

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response(null, {
      status: 200,
      headers: corsHeaders,
    });
  }

  try {
    const { question, language, userId } = await req.json();

    if (!question) {
      return new Response(
        JSON.stringify({ error: "Question is required" }),
        {
          status: 400,
          headers: {
            ...corsHeaders,
            "Content-Type": "application/json",
          },
        }
      );
    }

    const languageContext = {
      fr: "Réponds en français simple et clair.",
      en: "Respond in simple and clear English.",
      sw: "Jibu kwa Kiswahili rahisi na wazi.",
      ha: "Amsa da sauƙin Hausa.",
      wo: "Jëf ci Wolof bu ñëw.",
      bm: "Jabi ni Bamanankan ye.",
      pt: "Responda em português simples e claro.",
    };

    const systemPrompt = `Tu es Kora, une assistante virtuelle bienveillante pour les travailleurs ruraux en Afrique.
    Tu aides les utilisateurs à comprendre leurs droits, leur salaire, leurs contrats et leur protection sociale.

    ${languageContext[language] || languageContext.fr}

    Sois concise (2-3 phrases maximum), empathique et utilise un langage simple accessible aux personnes peu alphabétisées.
    Si la question concerne des données personnelles, indique à l'utilisateur de consulter la section appropriée de l'application.`;

    const claudeResponse = await fetch("https://api.anthropic.com/v1/messages", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "x-api-key": Deno.env.get("ANTHROPIC_API_KEY") || "",
        "anthropic-version": "2023-06-01",
      },
      body: JSON.stringify({
        model: "claude-3-haiku-20240307",
        max_tokens: 200,
        messages: [
          {
            role: "user",
            content: systemPrompt + "\n\nQuestion: " + question,
          },
        ],
      }),
    });

    if (!claudeResponse.ok) {
      const fallbackResponses = {
        fr: "Je suis là pour vous aider avec vos questions sur le travail. Consultez les sections Salaire, Contrats et Protection pour plus d'informations.",
        en: "I'm here to help with your work questions. Check the Salary, Contracts and Protection sections for more information.",
        sw: "Nipo hapa kukusaidia na maswali yako kuhusu kazi. Angalia sehemu za Mshahara, Mikataba na Ulinzi kwa habari zaidi.",
        ha: "Ina nan don taimaka muku da tambayoyin ku game da aiki. Duba sassan Albashi, Kwangila da Kariya don ƙarin bayani.",
        wo: "Dama fi ngir dimbalé sa ci wax yu jëkk ci liggéey. Xool ay seksiyoŋ Saleer, Kontara ak Rënd ngir am yeneeni xibaar.",
        bm: "Ne bɛ yan ka i dɛmɛ ni i ka baara ɲininkaliw ye. I ka Sara, Lasigiliden ani Kanw seksiyonw lajɛ walasa ka kunnafoni wɛrɛw sɔrɔ.",
        pt: "Estou aqui para ajudar com suas perguntas sobre trabalho. Consulte as seções Salário, Contratos e Proteção para mais informações.",
      };

      return new Response(
        JSON.stringify({
          response: fallbackResponses[language] || fallbackResponses.fr,
        }),
        {
          status: 200,
          headers: {
            ...corsHeaders,
            "Content-Type": "application/json",
          },
        }
      );
    }

    const data = await claudeResponse.json();
    const response = data.content[0].text;

    return new Response(
      JSON.stringify({ response }),
      {
        status: 200,
        headers: {
          ...corsHeaders,
          "Content-Type": "application/json",
        },
      }
    );
  } catch (error) {
    console.error("Error in Kora assistant:", error);

    return new Response(
      JSON.stringify({
        error: "Internal server error",
        response: "Je suis désolée, je rencontre un problème technique. Réessayez plus tard.",
      }),
      {
        status: 500,
        headers: {
          ...corsHeaders,
          "Content-Type": "application/json",
        },
      }
    );
  }
});
