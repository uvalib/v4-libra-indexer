import requests
import xml.etree.ElementTree as ET

def get_call_numbers(title, summary):
    base_url = "http://classify.oclc.org/classify2/Classify?"
    params = {
        "title": title,
        "summary": summary
    }
    response = requests.get(base_url, params=params)
    if response.status_code == 200:
        root = ET.fromstring(response.content)
        ddc = root.find('.//{http://classify.oclc.org}ddc/{http://classify.oclc.org}mostPopular/{http://classify.oclc.org}nsfa')
        lcc = root.find('.//{http://classify.oclc.org}lcc/{http://classify.oclc.org}mostPopular/{http://classify.oclc.org}nsfa')
        return ddc.text if ddc is not None else None, lcc.text if lcc is not None else None
    else:
        return None, None

# Example usage
title = "Freshwater Mussel Diet"
summary="Freshwater Mussel Diet Repository for files used in Isabella J. Maggard; Kayla B. Deel; Tina W. Etoll; Rachel C. Sproles; Timothy W. Lane; A. Bruce Cahoon, (2024) \"Freshwater Mussel Diet\" [insert journal name]. https://doi.org/10.18130/V3/RJ4EWF. Freshwater mussels (Mollusca: Unionidae) play a crucial role in freshwater river environments where they live in multi-species aggregations and often serve as long-lived benthic ecosystem engineers. Many of these species are imperiled and it is imperative that we understand their basic needs to aid in the reestablishment and maintenance of mussel beds in rivers. In an effort to expand our knowledge of the diet of these organisms, five species of mussel were introduced into enclosed systems in two experiments. In the first, mussels were incubated in water from the Clinch River (Virginia, USA) and in the second, water from a manmade pond at the Commonwealth of Virginia’s Aquatic Wildlife Conservation Center (AWCC) in Marion, VA. Quantitative PCR and eDNA metabarcoding were used to determine which planktonic microbes were present before and after the introduction of mussels into each experimental system. It was found that all five species preferentially consumed microeukaryotes over bacteria. Most microeukaryotic taxa, including Stramenopiles and Chlorophytes were quickly consumed by all five mussel species. We also found that they consumed fungi but not as quickly as the microalgae, and that one species of mussel, Ortmanniana pectorosa, consumed bacteria but only after preferred food sources were depleted. Our results provide evidence that siphon feeding Unionid mussels can select preferred microbes from mixed plankton, and mussel species exhibit dietary niche differentiation."
ddc, lcc = get_call_numbers(title,summary)
print(f"Dewey Decimal: {ddc}, LCC: {lcc}")
