import Backbone from "backbone"
import { DropDownItem } from "client/components/drop_down/drop_down_item.jsx"
import { mount } from "enzyme"
import React from "react"
import { SectionAdmin } from "../components/section"
import { SeriesAdmin } from "../components/series"
import { GucciAdmin } from "../index"

describe("Gucci Admin", () => {
  const curation = new Backbone.Model({
    name: "Gucci admin",
    type: "editorial-feature",
    sections: [
      {
        name: "I. Past",
      },
      {
        name: "II. Present",
      },
      {
        name: "III. Future",
      },
    ],
  })
  const props = {
    curation,
  }

  const getWrapper = (passedProps = props) => {
    return mount(<GucciAdmin {...passedProps} />)
  }

  it("renders sections and save buttons", () => {
    const component = getWrapper()
    expect(component.find(DropDownItem).length).toBe(3)
    expect(component.find(SeriesAdmin).length).toBe(1)
    expect(
      component
        .find("button")
        .at(0)
        .text()
    ).toMatch("Saved")
  })

  it("opens a section admin panel on click", () => {
    const component = getWrapper()
    component
      .find(".DropDownItem__title")
      .at(1)
      .simulate("click")
    expect(
      component
        .find(".DropDownItem__title")
        .at(1)
        .props()["data-active"]
    ).toBe(true)
    expect(component.find(SectionAdmin).length).toBe(1)
  })

  it("#onChange updates state.campaign and changes the save button text/color", () => {
    const component = getWrapper()
    const instance = component.instance() as GucciAdmin
    instance.onChange("name", "New Title")
    expect(instance.state.curation.get("name")).toMatch("New Title")
    expect(instance.state.isSaved).toBe(false)
    // FIXME TEST: Received: "black"
    // expect(component.find('button').at(0).props().style.color).toMatch('rgb(247, 98, 90)')
    expect(
      component
        .find("button")
        .at(0)
        .text()
    ).toMatch("Save")
  })

  it("#onChangeSection updates state.campaign", () => {
    const component = getWrapper()
    const instance = component.instance() as GucciAdmin
    instance.onChangeSection("featuring", "Many feminist artists", 0)
    expect(instance.state.curation.get("sections")[0].featuring).toMatch(
      "Many feminist artists"
    )
    expect(instance.state.isSaved).toBe(false)
    // FIXME TEST: Received: "black"
    // expect(component.find('button').at(0).props().style.color).toMatch('rgb(247, 98, 90)')
    expect(
      component
        .find("button")
        .at(0)
        .text()
    ).toMatch("Save")
  })

  it("Save button saves the curation", () => {
    const component = getWrapper()
    const instance = component.instance() as GucciAdmin
    instance.save = jest.fn()
    instance.onChange("name", "New Title")
    component
      .find("button")
      .at(0)
      .simulate("click")
    expect(instance.save).toHaveBeenCalled()
  })
})
