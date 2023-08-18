import cytoscape from "cytoscape"
import { setupDragAndDrop } from "./graph/dragAndDrop" 

export const Graph = {
    mounted() {
        var ctx = this.el;
        var cy = cytoscape({
            container: ctx,

            boxSelectionEnabled: false,

            style: [
                {
                    selector: 'node',
                    style: {
                        label: (node) => {
                            const name = node.data('name') || node.data('edge') || node.data('id');
                            return node.data('object_base') === true ? '' : name;
                        },
                        shape: (node) => node.data('object_base') === true ? 'round-rectangle' : 'ellipse',
                        backgroundColor: (node) => {
                            if (node.isChild) {
                                const parent = node.parent();
                                const color = parent.style('background-color');
                                return 'red' // TODO
                            } else {
                                return 'gray';
                            }
                        },
                    },
                    css: {
                        'border-color': 'gray',
                        'border-width': '1px',
                        'text-outline-color': '#FFF',
                        'text-outline-opacity': 0.9,
                        'text-outline-width': 2,
                        'font-size': 11,
                        'text-valign': 'center',
                        'text-halign': 'center'
                    }
                },
                {
                    selector: ':parent',
                    style: {
                        label: (node) => node.data('name') || node.data('id'),
                        backgroundColor: (node) => node.data('color') || 'gray',
                        shape: 'round-rectangle'
                    },
                    css: {
                        'background-opacity': 0.5,
                        'text-valign': 'top',
                        'text-halign': 'center',
                    }
                },
                {
                    selector: 'edge',
                    style: {
                        "line-style": (edge) => {
                            const edgeType = edge.data('name');
                            return (edgeType == 'inference_link') ? 'dashed' : 'solid'
                        }
                    },
                    css: {
                        'text-rotation': 'autorotate',
                        'text-outline-color': '#FFF',
                        'text-outline-opacity': 0.9,
                        'text-outline-width': 2,
                        'font-size': 11,
                        'curve-style': 'bezier',
                        'target-arrow-shape': 'triangle'
                    }
                }
            ],

            layout: {
                name: 'cose',
                padding: 5
            }
        });

        setupDragAndDrop(cy);

        this.handleEvent("add_points", ({ points }) => {
            console.log(points);
            cy.add(points);
            cy.layout({ name: 'random', fit: true}).run();
            cy.fit();
        });

    }
}