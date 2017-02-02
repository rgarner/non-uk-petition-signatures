setupDropdown = (petitionsJson) ->
  petitionsMenu = $('.petitions.dropdown-menu')

  appendPetitionItem = (petitionJson) ->
    petitionUrl = new PetitionUrl(petitionJson.links.self)

    petitionsMenu.append(
      """
        <li>
          <a href='#/petitions/#{petitionUrl.petitionId}'>#{petitionJson.attributes.action}</a>
        </li>
      """
    )

  appendPetitionItem(petition) for petition in petitionsJson.data

jQuery ->
  if document.getElementById('drpPetitions')
    $.ajax
      url: "https://petition.parliament.uk/petitions.json"
      dataType: "json"
      error: (jqXHR, textStatus, errorThrown) ->
        console.log("Couldn't get petitions JSON - #{textStatus}: #{errorThrown}")
      success: (petitionsJson) ->
        setupDropdown(petitionsJson, (url) -> window._pageManager.setup(url))

